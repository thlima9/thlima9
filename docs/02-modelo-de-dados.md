# 02 — Modelo de dados

## Unidades de página
- Todas as coordenadas ficam em **unidades de página (u)**: **1 u = 1 ponto tipográfico = 1/72 polegada**.
- Nada é gravado em pixels. A tela converte u → pixels com `escala = larguraDaTela / page.width × zoom`.
- Isso garante que a página "Tab S7" ocupe a tela do tablet e seja apenas redimensionada na web.
- Conversão para a régua: `cm = u / 72 × 2,54`.

## Tamanhos de página (`page_size`)
| Código | Largura × altura (u) | Observação |
|---|---|---|
| `tab_s7_landscape` | 1280 × 800 | 16:10 exato, ocupa a tela em paisagem |
| `tab_s7_portrait` | 800 × 1280 | 16:10 exato, ocupa a tela em retrato |
| `a4_portrait` / `a4_landscape` | 595 × 842 / 842 × 595 | |
| `a5_portrait` / `a5_landscape` | 420 × 595 / 595 × 420 | |
| `letter_portrait` / `letter_landscape` | 612 × 792 / 792 × 612 | |
| `custom` | definido | páginas importadas de PDF usam o tamanho do PDF |

> Tab S7: o "ocupa a tela" vale com a barra de ferramentas recolhível/sobreposta. Com a barra fixa, a página encaixa pela largura e rola.

## Modelos de fundo (`template`)
`blank`, `ruled_narrow` (linhas a cada 20 u), `ruled_wide` (28 u), `grid_5mm` (14,17 u), `dotted_5mm`, `cornell`. Cor do papel em `paper_color`: `white` `#FFFFFF`, `cream` `#FBF6E9`, `dark` `#1E1E1E`.
Os modelos são **desenhados por código** (`shared/render/templates.dart`), não são imagens. Tablet e web desenham igual.

## Entidades

Todas têm: `id uuid` (gerado no **tablet**), `user_id`, `created_at`, `updated_at`, `deleted_at` (exclusão lógica → lixeira).

### folder
`id, parent_id?, name, sort_index, is_favorite`

### notebook
`id, folder_id?, title, cover (json: {style, color}), default_page_size, default_template, default_paper_color, scroll_direction ('vertical'|'horizontal'), sort_index, is_favorite, last_opened_at, thumbnail_path?`

### page
`id, notebook_id, sort_index (double; reordenar = valor entre vizinhos), width, height, page_size, template, paper_color, pdf_asset_id?, pdf_page_index?, is_bookmarked, bookmark_title?, thumbnail_path?, recognized_text? (fase 6)`

### stroke (traço)
| Campo | Tipo | Descrição |
|---|---|---|
| `id` | uuid | |
| `page_id` | uuid | |
| `notebook_id` | uuid | redundante, para filtrar o realtime por caderno |
| `tool` | text | `pen_ballpoint`, `pen_fountain`, `pen_brush`, `highlighter`, `shape` |
| `color` | bigint | ARGB 32 bits (ex.: `0xFF1A1A1A`) |
| `width` | real | espessura base em u |
| `points` | text | pontos codificados (ver `docs/04`), base64 |
| `point_count` | int | |
| `bbox` | real[4] | `[minX, minY, maxX, maxY]` em u, já com a espessura |
| `z` | bigint | ordem de desenho (crescente) |
| `shape` | jsonb? | se `tool = shape`: `{type, params}` (ex.: `{"type":"ellipse","cx":..,"cy":..,"rx":..,"ry":..,"rot":..}`) |

Traços são **imutáveis**: mudar significa apagar (`deleted_at`) e criar um novo. A única exceção é a mudança de cor/transformação pelo laço, que pode fazer `update` em `color`/`points`/`bbox` do mesmo id.

### element (texto e imagem)
`id, page_id, notebook_id, type ('text'|'image'), z, x, y, width, height, rotation, data jsonb`
- texto: `{ "text": "...", "font_size": 16, "color": 4278190080, "font": "sans|serif|mono", "bold": false }`
- imagem: `{ "asset_id": "..." }`

### asset (arquivos no Storage)
`id, kind ('pdf'|'image'), storage_path ('{user_id}/{asset_id}.pdf'), sha256, byte_size, uploaded (bool, só local)`

### device_state (para "seguir tablet" na web)
Uma linha por usuário: `user_id, open_notebook_id?, open_page_id?, updated_at`.

## Banco local (Drift)
- As mesmas tabelas e colunas, mais `dirty bool` (precisa enviar) e a tabela **`outbox`** (ver `docs/03`).
- `points` pode ficar como `BLOB` local (bytes crus) e virar base64 só no envio.

## Banco remoto
SQL completo em `supabase/migrations/0001_init.sql`.
