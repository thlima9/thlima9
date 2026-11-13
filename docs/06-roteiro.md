# 06 — Roteiro de desenvolvimento

Marque `[x]` ao concluir. Cada fase termina com algo que **o usuário testa no tablet/web**. Não avance de fase sem os critérios de aceite.

---

## Fase 0 — Fundação e teste da caneta
- [ ] `flutter create --platforms=android,web --org com.thnotes --project-name th_notes app`
- [ ] Android: `minSdk 26`, `applicationId com.thnotes.app`, nome "Th Notes", ícone simples, orientação livre.
- [ ] Adicionar os pacotes de `docs/01`; estrutura de pastas de `CLAUDE.md`; `analysis_options.yaml` com `flutter_lints`.
- [ ] `env.example.json` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`), `env.json` no `.gitignore`.
- [ ] `core/ink/point_codec.dart` + testes; `core/ink/brushes.dart`; `core/model/page_size.dart` (tabela de `docs/02`).
- [ ] **Protótipo de tinta**: tela com página Tab S7, caneta com pressão (perfect_freehand), camada fixa + ativa, rejeição de palma, botão da S Pen → borracha por traço, contador de FPS (debug).
- [ ] GitHub Actions: `flutter analyze` + `flutter test` em cada push.

**Aceite:** no Tab S7, a escrita é fluida, a pressão varia a espessura, a palma não risca e o botão da caneta apaga. Os testes do codec passam.

---

## Fase 1 — Editor de uma página completo
- [ ] Modelos de fundo (todos de `docs/02`) e cores do papel em `shared/render/templates.dart`.
- [ ] Ferramentas: 3 canetas, marca-texto (atrás da tinta, opção reta), borracha por traço / precisa / só marca-texto, com tamanhos.
- [ ] Paleta (6 favoritas + seletor), 3 espessuras favoritas por ferramenta (salvas nas preferências).
- [ ] Zoom 50–800% e rolagem; ajustar à tela.
- [ ] Desfazer/refazer (botões + gestos de 2/3 dedos).
- [ ] Barra de ferramentas recolhível.
- [ ] Desempenho: 1000 traços sem travar (teste de carga gerando traços).

**Aceite:** dá para fazer uma página de anotações real só no tablet (ainda sem salvar).

---

## Fase 2 — Cadernos, páginas e organização (local)
- [ ] Drift: tabelas de `docs/02` + outbox (o sync ainda não envia), migrações do Drift versionadas.
- [ ] Salvar e carregar traços/páginas automaticamente (sem botão de salvar).
- [ ] Biblioteca: pastas, subpastas, cadernos com capa, criar/renomear/mover/duplicar/excluir, arrastar para mover.
- [ ] Novo caderno com tamanho (padrão Tab S7 na orientação atual), modelo e cor do papel.
- [ ] Editor com várias páginas: rolagem vertical contínua e horizontal; adicionar/duplicar/excluir/reordenar; painel de páginas com miniaturas; mudar o modelo de uma página.
- [ ] Favoritos, Recentes, Lixeira (restaurar; limpeza automática após 30 dias), busca por título, ordenação.
- [ ] Marcadores de página + sumário.

**Aceite:** dá para usar como caderno de verdade, offline; fechar e reabrir o app mantém tudo.

---

## Fase 3 — Supabase, sincronização e web ao vivo ⭐
- [ ] Aplicar `supabase/migrations/0001_init.sql`; criar o usuário; desativar cadastros (ver `docs/07`).
- [ ] Login (tablet e web), sessão persistente, logout.
- [ ] Syncer (outbox → upsert em lotes, ordem por tabela, backoff, indicador de nuvem, "sincronizar agora").
- [ ] Miniaturas → Storage `thumbnails`.
- [ ] Broadcast de tinta ao vivo, `erase` e `focus`; `device_state`.
- [ ] **Web**: login, biblioteca (somente leitura), visualizador com carregamento sob demanda, realtime (`postgres_changes` + broadcast), recarregar ao reconectar, "Seguir tablet", indicador ao vivo.
- [ ] Restaurar do servidor (tablet).
- [ ] Publicar a web (Cloudflare Pages ou similar), passo a passo em `docs/07`.

**Aceite:** escrevendo no tablet, o traço aparece no navegador do computador em menos de ~1 s, enquanto é feito. Com o tablet offline, as notas sobem sozinhas quando a rede volta. Apagar no tablet também apaga na web.

---

## Fase 4 — Ferramentas avançadas
- [ ] Laço (mover, escalar, girar, cor, copiar/recortar/colar/duplicar/apagar).
- [ ] Reconhecimento de formas (segurar ao terminar).
- [ ] Caixa de texto (criar, editar, mover, fonte/tamanho/cor).
- [ ] Imagens (galeria/câmera → comprimir a no máx. 2048 px → asset → Storage).
- [ ] Régua (mover/girar, traço reto, cm), transferidor e fita métrica (fixável na página).
- [ ] Tudo aparece corretamente na web.

**Aceite:** todas as ferramentas de `docs/00` funcionam e sincronizam.

---

## Fase 5 — PDF
- [ ] Importar PDF (novo caderno ou inserir páginas): cada página do PDF vira uma `page` com `pdf_asset_id`/`pdf_page_index` e tamanho do PDF.
- [ ] Renderizar o PDF de fundo (pdfrx) com cache por página/zoom, nos dois lados.
- [ ] Exportar caderno/página como PDF (vetorial: traços como caminhos preenchidos sobre o PDF original/fundo). No tablet: salvar em arquivo. Na web: download.

**Aceite:** um PDF de 100 páginas abre rápido, aceita anotação e aparece anotado na web.

---

## Fase 6 — Busca na escrita à mão
- [ ] ML Kit Digital Ink (modelo `pt-BR` baixado uma vez) reconhece as páginas em segundo plano, depois de alguns segundos sem editar.
- [ ] `page.recognized_text` sincronizado; índice de texto no Postgres (migração nova).
- [ ] Busca no tablet e na web com lista de resultados → abre a página.

**Aceite:** buscar uma palavra escrita à mão encontra a página.

---

## Fase 7 — Acabamento
- [ ] Tema escuro (inclusive papel escuro com tinta preta invertida opcionalmente).
- [ ] Desempenho de cadernos grandes (500+ páginas), cache de miniaturas.
- [ ] Exportar backup completo (zip) e importar.
- [ ] Revisão de erros e mensagens; tela "Sobre".
- [ ] Checklist final de testes no Tab S7.
