# Plano — App de notas manuscritas (estilo GoodNotes) + visualização web em tempo real

> Alvo principal: **Samsung Galaxy Tab S7** (11", 2560×1600, 16:10, S Pen com pressão e inclinação, tela de 120 Hz).
> Objetivo: escrever no tablet com a sensação de um app nativo e **ver as anotações no navegador, atualizadas ao vivo**.

---

## 1. Escopo

### O que entra (núcleo do GoodNotes)
| Área | Funções |
|---|---|
| **Escrita** | Caneta com pressão (esferográfica, tinteiro, pincel), marca-texto (fica atrás da tinta, opção de linha reta), borracha (por traço, precisa, só marca-texto), paleta de cores e espessuras favoritas, desfazer/refazer |
| **Seleção** | Laço: mover, redimensionar, girar, mudar cor, copiar/colar, apagar |
| **Formas** | Segurar a caneta no fim do traço para virar forma perfeita (linha, seta, retângulo, círculo, triângulo) |
| **Medida** | Régua virtual na tela (arrastar/girar com 2 dedos, caneta "gruda" nela), leitura em cm/mm e ângulo, transferidor; ferramenta de medir distância entre dois pontos |
| **Conteúdo extra** | Caixa de texto, imagens (galeria/câmera), importar PDF e anotar por cima |
| **Páginas** | Modelos: em branco, pautado, quadriculado, pontilhado, Cornell; tamanhos **"Tab S7 retrato/paisagem" (16:10, ocupa a tela inteira)**, A4, A5, Carta; adicionar/duplicar/reordenar/excluir páginas; rolagem vertical ou horizontal |
| **Organização** | Pastas e subpastas, cadernos com capa, miniaturas das páginas, favoritos, marcadores de página, sumário, recentes, lixeira |
| **Busca** | Por título; depois, busca no texto manuscrito (reconhecimento offline em português) |
| **Entrada** | Rejeição de palma (S Pen escreve, dedo rola/dá zoom), botão da S Pen alterna para borracha, gestos (2 dedos = desfazer, 3 = refazer) |
| **Web** | Biblioteca completa no navegador, visualização fiel das páginas, **traço aparecendo enquanto é escrito**, zoom, navegação, exportar PDF |

### O que fica de fora (deliberadamente)
Compartilhamento/colaboração com outras pessoas, envio por e‑mail/links públicos, comunidade/loja de modelos, recursos de IA, gravação de áudio, figurinhas/stickers, apresentação/modo professor. (Podem voltar depois, se quiser.)

---

## 2. Arquitetura

```
┌──────────────────────────┐         ┌───────────────────────────┐        ┌───────────────────────┐
│  App Android (Tab S7)    │         │  Backend (Supabase)       │        │  App Web (navegador)  │
│  Kotlin + Compose        │ ──────▶ │  Postgres  (dados)        │ ─────▶ │  Next.js + TypeScript │
│  androidx.ink (tinta)    │  HTTPS  │  Realtime  (ao vivo)      │  WS    │  Canvas 2D            │
│  Room (banco local)      │ ◀────── │  Storage   (PDF/imagens)  │ ◀───── │  Somente leitura (v1) │
│  Fila de sincronização   │   WS    │  Auth + RLS (só você)     │        │                       │
└──────────────────────────┘         └───────────────────────────┘        └───────────────────────┘
```

### 2.1 Tablet: **Android nativo (Kotlin)** — recomendação
- O que mais importa num app desses é **latência da caneta**. No Android nativo dá para usar:
  - **Jetpack Ink (`androidx.ink`)**: biblioteca oficial do Google para tinta — pincéis com pressão/inclinação, geometria dos traços, borracha e renderização.
  - **Renderização em front buffer (`androidx.graphics` low-latency)**: desenha o traço direto no buffer da tela, quase sem atraso visível.
  - `MotionEvent` com histórico de pontos (a S Pen manda pontos entre frames), `TOOL_TYPE_STYLUS` vs `TOOL_TYPE_FINGER` para rejeição de palma, botão lateral da S Pen.
- UI com **Jetpack Compose**; tela de desenho como `View`/`SurfaceView` dedicada (por desempenho).
- **Room (SQLite)** como fonte da verdade local → o app funciona 100% offline.
- PDF: `PdfRenderer` do Android (renderiza páginas como fundo).
- Reconhecimento de escrita: **ML Kit Digital Ink Recognition** (offline, tem português).

> Alternativas consideradas: Flutter/React Native — uma base só para tudo, mas pior latência de caneta e sem acesso direto ao Jetpack Ink. Como o tablet é Android e a web é só visualização, o nativo compensa.

### 2.2 Backend: **Supabase**
- **Postgres** guarda pastas, cadernos, páginas e traços.
- **Realtime** em dois canais por página:
  1. *Mudanças confirmadas* (traço salvo, apagado, movido) via inserts no banco.
  2. *Broadcast de "tinta ao vivo"*: pontos do traço em andamento, ~20–30 envios/s, sem gravar no banco — é isso que faz a web mostrar o traço **enquanto você escreve**.
- **Storage** para PDFs importados, imagens e miniaturas.
- **Auth** (e‑mail/senha ou Google) + **Row Level Security**: só sua conta lê/escreve.
- O plano gratuito atende bem um usuário; dá para hospedar por conta própria depois (Supabase é open source).

### 2.3 Web: **Next.js + TypeScript**
- Biblioteca (pastas/cadernos/miniaturas) → visualizador de páginas.
- Renderização em **Canvas 2D** com o **mesmo algoritmo de traço** do tablet (ver §3.3) — fidelidade visual é requisito.
- Assina o canal da página aberta e desenha traços novos e a tinta ao vivo.
- PDFs de fundo com **pdf.js**.
- Hospedagem: Vercel (grátis) ou junto com o Supabase.
- v1 somente leitura; edição leve (ex.: renomear, reorganizar) pode vir depois.

---

## 3. Modelo de dados e sincronização

### 3.1 Coordenadas independentes de tela
Tudo é gravado em **unidades de página** (ex.: 1 unidade = 1/72 pol.), nunca em pixels. A página "Tab S7 paisagem" tem proporção 16:10 exata; ao abrir no tablet ela ocupa a tela, e na web é apenas escalada. Isso resolve a "diagramação da folha para corresponder ao tamanho da tela".

### 3.2 Entidades
```
folder      (id, parent_id, name, order, updated_at, deleted_at)
notebook    (id, folder_id, title, cover, default_template, page_size, updated_at, deleted_at)
page        (id, notebook_id, index, width, height, template, background_pdf_ref?, updated_at, deleted_at)
stroke      (id, page_id, tool, color, width, points_blob, bbox, z, created_at, deleted_at)
element     (id, page_id, type[text|image|shape], data_json, transform, z, updated_at, deleted_at)
asset       (id, kind[pdf|image], storage_path, sha256)
```
- `points_blob`: pontos (x, y, pressão, inclinação, tempo) **compactados** (delta + inteiros + gzip) — uma página cheia fica em dezenas de KB.
- `bbox` permite carregar/desenhar só o que está visível e acelera borracha/laço.

### 3.3 Por que a sincronização fica simples (e sem conflitos)
- **Traços são imutáveis** e têm UUID gerado no tablet. Operações viram eventos:
  `add_stroke`, `delete_stroke` (borracha marca `deleted_at`), `transform_strokes` (laço gera novos traços e apaga os antigos).
- Como só existe **um escritor principal** (o tablet), "último a gravar vence" por registro é suficiente. Não é preciso CRDT.
- **Offline-first**: cada operação vai primeiro para o Room e para uma **fila de saída (outbox)**; um `WorkManager` envia quando há rede, com retentativas. IDs gerados no cliente tornam o reenvio idempotente.
- Borracha "precisa" (que corta traços ao meio) = apagar o traço original + criar os pedaços restantes.
- Renderização idêntica: tablet e web leem os **mesmos pontos brutos + parâmetros do pincel**. Para garantir fidelidade total, opção recomendada: o tablet grava também o **contorno já calculado** (polígono gerado pelo Jetpack Ink), e a web só preenche esse polígono. Assim não é preciso reimplementar o algoritmo de pincel em TypeScript.

---

## 4. Fases de desenvolvimento

Cada fase termina com algo usável no tablet.

| Fase | Entrega | Duração estimada* |
|---|---|---|
| **0. Fundação** | Repositório (monorepo `android/`, `web/`, `supabase/`), projeto Android, projeto Supabase, CI simples. **Protótipo de latência**: uma tela em branco com S Pen + Jetpack Ink + front buffer, medido no Tab S7. | 1 semana |
| **1. Núcleo de escrita** | Página com modelos e tamanhos (incl. Tab S7), caneta com pressão, marca-texto, borracha por traço, cores/espessuras, desfazer/refazer, zoom e rolagem com dedos, rejeição de palma, botão da S Pen. Salvamento local (Room). | 2–3 semanas |
| **2. Organização** | Biblioteca: pastas, cadernos com capa, miniaturas, adicionar/reordenar/duplicar páginas, favoritos, recentes, lixeira, busca por título. | 2 semanas |
| **3. Sync + Web (MVP)** | Login, schema + RLS no Supabase, outbox e sincronização, web com biblioteca e visualizador, **tinta ao vivo** via broadcast. *A partir daqui o objetivo principal já funciona.* | 3 semanas |
| **4. Ferramentas avançadas** | Laço (mover/redimensionar/girar/recolorir), reconhecimento de formas, borracha precisa, caixa de texto, imagens, **régua/transferidor/medição**. | 3 semanas |
| **5. PDF** | Importar PDF como caderno, anotar por cima, sincronizar o arquivo, exibir na web com pdf.js; exportar caderno como PDF (local e na web). | 2 semanas |
| **6. Busca na escrita** | ML Kit (português, offline) indexando traços em segundo plano; busca no tablet e na web com destaque na página. | 1–2 semanas |
| **7. Acabamento** | Marcadores e sumário, modo escuro, desempenho em cadernos grandes (carregamento por página/bbox), backup/exportação completa, testes no aparelho. | contínuo |

\* Estimativas para uma pessoa em ritmo de projeto paralelo, com o Claude escrevendo boa parte do código.

**MVP pessoal** = Fases 0 a 3 (~8–9 semanas): escrever bem no tablet, organizar em cadernos e ver tudo ao vivo no navegador.

---

## 5. Riscos e como tratar

| Risco | Mitigação |
|---|---|
| Latência da caneta pior que a do GoodNotes | Fase 0 existe só para isso; medir no Tab S7 antes de construir o resto |
| Web desenhar diferente do tablet | Gravar o contorno calculado pelo tablet (§3.3) |
| Cadernos grandes ficarem lentos | Carregar por página, cache de miniaturas, consultar traços por `bbox` |
| Perda de dados | Room local como verdade + outbox + `deleted_at` (lixeira) em vez de apagar de fato |
| Custos | Plano gratuito do Supabase + Vercel cobre um usuário; traços compactados |

---

## 6. Decisões em aberto
1. **Experiência com Kotlin/Android?** Se preferir algo mais familiar, Flutter é a alternativa (com perda de latência).
2. **Web só leitura na v1** — ou quer escrever/editar pelo navegador também (com mouse ou outro tablet)?
3. **Supabase gerenciado** (mais rápido) ou **servidor próprio** desde o início?
4. **Nome do app.**

## 7. Próximo passo
Começar a **Fase 0**: criar o monorepo, o projeto Android com o protótipo de tinta de baixa latência e o projeto Supabase. Para testar no tablet: ativar *Opções do desenvolvedor → Depuração USB* (ou depuração sem fio) no Tab S7 e instalar o APK pelo Android Studio.
