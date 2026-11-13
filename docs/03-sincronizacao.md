# 03 — Sincronização (tablet → Supabase → web)

## Princípios
1. **O tablet é o único que escreve.** A web só lê. Sem conflitos, sem CRDT.
2. **Offline primeiro:** toda alteração vai para o Drift na hora. O envio acontece depois, quando houver rede.
3. **IDs gerados no tablet** (UUID v4) + `upsert` → reenviar a mesma coisa é seguro (idempotente).
4. **Nunca apagar de verdade:** exclusão = `deleted_at`. A limpeza da lixeira (30 dias) apaga de fato, no tablet e no servidor.

## Dois caminhos de dados

### A) Dados confirmados (persistentes)
```
ação no editor ──► transação Drift: grava a entidade + insere na outbox
                         │
                 Syncer (loop no app) ── a cada mudança na outbox ou a cada 5 s
                         │   lê até 200 itens, agrupa por tabela
                         ▼
             supabase.from(tabela).upsert(lote)  ──► Postgres
                         │ ok → remove da outbox      erro → backoff 2s,4s,8s…60s
                         ▼
             Realtime (postgres_changes) ──► web atualiza a página aberta
```
- **outbox** (Drift): `seq autoincrement, table_name, row_id, op ('upsert'|'hard_delete'), created_at, attempts`.
- Sem duplicata: se já houver item pendente para o mesmo `(table_name,row_id)`, mantém só um. O envio lê a linha atual do Drift na hora de enviar.
- **Ordem**: enviar `folder` → `notebook` → `asset` → `page` → `stroke`/`element` (chaves estrangeiras).
- **Arquivos (PDF/imagem)**: antes de enviar a linha `asset`, faz upload para o Storage `assets/{user_id}/{asset_id}.{ext}`; só então faz o upsert da linha com `uploaded=true`.
- **Miniaturas**: ao sair de uma página editada, o tablet gera um PNG (largura 400 px) e envia para `thumbnails/{user_id}/{page_id}.png` (upsert). A primeira página vira a miniatura do caderno.
- O ícone de nuvem na biblioteca mostra o estado: sincronizado / pendente (n) / offline / erro.

### B) Tinta ao vivo (efêmera, não grava)
- Canal Realtime **Broadcast privado** por usuário: `live:{user_id}` (abrir com `RealtimeChannelConfig(private: true)`; as políticas estão na migração 0001).
- Durante o traço, o editor envia a cada **~50 ms** (no máximo 20/s) os **pontos novos** desde o último envio:
```json
{ "type": "ink", "page_id": "...", "stroke_id": "...", "tool": "pen_fountain",
  "color": 4278190080, "width": 2.0, "seq": 3, "points": "<base64 do mesmo codec>" }
```
- Ao levantar a caneta: `{ "type": "ink_end", "page_id", "stroke_id" }`. O traço definitivo chega depois pelo caminho A e substitui a versão provisória com o mesmo `stroke_id`.
- Também por broadcast: `{ "type": "erase", "page_id", "stroke_ids": [...] }` e `{ "type": "focus", "notebook_id", "page_id" }` (usado pelo "seguir tablet").
- O envio do broadcast **nunca** bloqueia o desenho: roda fora do caminho de entrada da caneta e descarta mensagens se a rede estiver lenta.
- Se a web perder mensagens, nada se perde: o caminho A sempre corrige.

## Web (visualizador)
1. Login → carrega pastas e cadernos (`deleted_at is null`).
2. Abrir caderno → carrega `page` do caderno; para cada página visível, carrega `stroke` e `element` (`page_id = X and deleted_at is null`, ordenado por `z`). Carrega as páginas sob demanda, conforme a rolagem (2 de folga).
3. Assina:
   - `postgres_changes` em `stroke`, `element` e `page` filtrando `notebook_id`/`page_id` relevantes (ou geral por usuário e filtrar no cliente: com um usuário só, é mais simples);
   - broadcast `live:{user_id}`.
4. Ao reconectar (aba volta do segundo plano, rede volta), **recarrega** a página atual para não perder nada.
5. `device_state` + broadcast `focus` → modo "seguir tablet".

## Restaurar (reinstalação do app ou tablet novo)
Configurações → "Restaurar do servidor": baixa todas as tabelas para o Drift (paginando de 1000 em 1000) e os arquivos do Storage. Só fica disponível quando o banco local está vazio, ou depois de uma confirmação.

## Limites esperados
Uma página cheia tem ~300 traços × ~150 pontos × 6 bytes ≈ 270 KB (base64 ≈ 360 KB). Mil páginas ≈ 360 MB, perto do limite de 500 MB do plano gratuito. Se chegar perto: compressão (codec v2 com delta + varint) já está prevista no campo de versão.
