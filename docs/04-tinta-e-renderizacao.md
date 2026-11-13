# 04 — Tinta, ferramentas e renderização

## Captura da S Pen
- Use um `Listener` (eventos de ponteiro crus), **não** `GestureDetector`, na área da página.
- `event.kind == PointerDeviceKind.stylus` → desenha. `invertedStylus` → borracha. `touch` → rolagem/zoom (via `InteractiveViewer` ou controle próprio). Se "dedo escreve" estiver ativo, `touch` com um dedo também desenha.
- **Botão da S Pen**: `event.buttons & kSecondaryStylusButton != 0` (ou `kPrimaryStylusButton`, conforme o aparelho) → borracha temporária. Teste no Tab S7 e registre aqui o valor que funcionou.
- Pressão: `event.pressure` normalizado entre `pressureMin` e `pressureMax`. Se vier sempre 0 ou 1 (dedo), use 0,5.
- Converta cada ponto para **unidades de página** antes de guardar.
- Descarte pontos a menos de 0,3 u do anterior.

## Codec de pontos — versão 1 (obrigatório, igual nos dois lados)
Cada ponto ocupa 6 bytes, little-endian:
| Campo | Tipo | Conversão |
|---|---|---|
| x | Int16 | `round(x_u × 8)` → precisão de 1/8 u, até 4095 u |
| y | Int16 | `round(y_u × 8)` |
| p | Uint16 | `round(pressão × 65535)` |

- O buffer começa com **1 byte de versão** (`0x01`), seguido dos pontos. Texto = base64 padrão (com `=`).
- Implementação em `core/ink/point_codec.dart` com `encode(List<InkPoint>) → String` e `decode(String) → List<InkPoint>`.
- Teste obrigatório: ida e volta com erro ≤ 1/16 u e pressão ≤ 1/65535.

## Ferramentas e parâmetros do `perfect_freehand`
| Ferramenta | size | thinning | smoothing | streamline | simulatePressure | outros |
|---|---|---|---|---|---|---|
| `pen_ballpoint` | width×2 | 0,15 | 0,5 | 0,5 | false | — |
| `pen_fountain` | width×2 | 0,6 | 0,6 | 0,4 | false | — |
| `pen_brush` | width×2 | 0,75 | 0,7 | 0,4 | false | taper start/end 20 |
| `highlighter` | width×2 | 0 | 0,5 | 0,6 | false | cor com alpha 0x55, pontas quadradas |

Os valores são iniciais e podem ser ajustados nos testes, mas ficam em **um só arquivo** (`core/ink/brushes.dart`), compartilhado pelo tablet e pela web.

## Renderização
**Ordem de pintura de uma página:**
1. Cor do papel → 2. Modelo (linhas/grade) → 3. PDF de fundo → 4. Marca-texto → 5. Tinta e formas (por `z`) → 6. Elementos (texto/imagens, por `z`) → 7. Seleção e guias (só no editor).

**Desempenho (editor):**
- **Camada fixa**: os traços já concluídos são gravados em um `ui.Picture` (refeito só quando a página muda). Em zoom parado, rasterize em `ui.Image` na resolução atual.
- **Camada ativa**: só o traço em andamento, num `CustomPainter` separado, com `RepaintBoundary`. Atualizada a cada evento, sem reconstruir widgets.
- Ao levantar a caneta: o traço vai para a camada fixa, depois para o Drift, depois para a outbox, tudo de forma assíncrona.
- Só pinte os traços cujo `bbox` cruza a área visível.
- Meta: **sem frames perdidos a 120 Hz** em uma página com 1000 traços. Medir com o DevTools no aparelho, em modo `--profile`.

**Web:** usa o mesmo `PagePainter`. Na web, gere o build com o renderizador padrão (CanvasKit).

## Borracha
- **Por traço**: o círculo da borracha (raio r) cruza o caminho do traço (distância ponto–segmento ≤ r + width/2) → `deleted_at`.
- **Precisa**: divide o traço nos trechos fora do círculo. Apaga o original e cria os pedaços como traços novos.
- **Só marca-texto**: igual à borracha por traço, mas filtrando `tool = highlighter`.
- Cada gesto de borracha é **uma** ação de desfazer.

## Laço
- O caminho livre forma um polígono. Um traço entra na seleção se ≥ 50% dos pontos estiverem dentro (ponto-em-polígono). Um elemento entra se o seu centro estiver dentro.
- Alças: mover (arrastar dentro), escalar (cantos, mantendo a proporção), girar (alça superior).
- Ao soltar: aplica a matriz aos pontos (a espessura escala junto) e faz `update` nos registros.
- Menu: cor, copiar, recortar, duplicar, apagar. A área de transferência é interna ao app.

## Reconhecimento de formas
- Disparo: a caneta fica parada (movimento < 2 u) por 500 ms antes de levantar.
- Teste de linha → triângulo → retângulo → elipse, com tolerância de 8% da diagonal do bbox. Seta = linha + 2 segmentos curtos no fim (variante: segure ao terminar a ponta).
- O resultado vira `tool = shape` com `shape` em JSON e `points` com o contorno amostrado (a web só precisa dos points).

## Régua, transferidor e fita
- **Régua**: retângulo semitransparente de 15 cm, por cima da página. Dois dedos movem e giram; o ângulo encaixa a cada 15° (mostra o ângulo atual).
  - Se a caneta começar a até 12 u da borda, o traço é projetado sobre a borda: sai reto e mostra o comprimento em cm durante o traço.
  - Marcações em cm/mm calculadas com 72 u = 2,54 cm (tamanho real da página, não da tela).
- **Transferidor**: centro e duas semirretas arrastáveis; mostra o ângulo.
- **Fita métrica**: toque em dois pontos → mostra a distância em cm. Pode ser fixada na página como forma (`shape: {"type":"measure"}`) com o rótulo.
- Régua, transferidor e fita (quando não fixada) não são salvos nem sincronizados.

## Desfazer/refazer
- Pilha de comandos por página (máx. 100): `AddStrokes`, `DeleteStrokes`, `TransformItems`, `AddElement`, `EditElement`, `ChangePageTemplate`…
- Desfazer também grava no Drift e na outbox, então a web acompanha.
