# 05 — Interface

Estilo: limpo, claro, inspirado no GoodNotes; Material 3; tema claro e escuro; botões grandes (alvo ≥ 44 dp) para uso com caneta.

## Telas do tablet

### 1. Login
E-mail e senha (uma vez; a sessão fica salva).

### 2. Biblioteca
```
┌───────────────────────────────────────────────────────────────┐
│ Th Notes           [Buscar........]    ☁ sincronizado   ⚙     │
├───────────┬───────────────────────────────────────────────────┤
│ Todos     │  Pastas > Faculdade                 Ordenar ▾  ＋  │
│ Favoritos │  ┌────┐ ┌────┐ ┌────┐ ┌────┐                      │
│ Recentes  │  │ 📁 │ │capa│ │capa│ │capa│                      │
│ Lixeira   │  └────┘ └────┘ └────┘ └────┘                      │
│ ───────── │  Cálculo  Física  Notas  Diário                    │
│ Pastas ▸  │                                                    │
└───────────┴───────────────────────────────────────────────────┘
```
- ＋ → Novo caderno | Nova pasta | Importar PDF.
- **Novo caderno**: título, capa, tamanho (padrão **Tab S7** na orientação atual), modelo, cor do papel, com prévia.
- Toque longo em um item → renomear, mover, duplicar, favoritar, mudar a capa, excluir.
- Arrastar e soltar para mover entre pastas.

### 3. Editor
```
┌───────────────────────────────────────────────────────────────┐
│ ←  Cálculo · p. 3/12   ▦ páginas  🔖  ↶ ↷        ＋pág  ⋯      │
├───────────────────────────────────────────────────────────────┤
│ ✎ ✎ ✎ │ 🖍 │ ⌫ │ ◌laço │ ⬠ │ T │ 🖼 │ 📏 ‖ ● ● ● ● ● ● ‖ ─ ━ ▬ │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│                      (página)                                 │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```
- A barra de ferramentas pode ser **recolhida** (botão ou toque com 3 dedos), deixando a página em tela cheia.
- Tocar de novo na ferramenta ativa abre as opções dela (estilo da caneta, tipo de borracha, tamanho…).
- ▦ abre o **painel de páginas**: miniaturas para navegar, reordenar, duplicar, excluir, mudar o modelo; aba **Marcadores** (sumário).
- ⋯ → mudar o modelo desta página, rolagem vertical/horizontal, exportar PDF, configurações do caderno.
- Indicador discreto de sincronização no topo.

### Gestos (editor)
| Gesto | Ação |
|---|---|
| S Pen | desenha com a ferramenta atual |
| S Pen + botão | borracha temporária |
| 1 dedo | rola (se "dedo escreve" estiver desligado) |
| Pinça | zoom |
| Toque com 2 dedos | desfazer |
| Toque com 3 dedos | refazer |
| Toque duplo com 2 dedos | ajustar a página à tela |

### 4. Configurações
Conta, estado da sincronização (pendências, sincronizar agora, último erro), "dedo escreve", ferramenta do botão da S Pen, tema, tamanho e modelo padrão, restaurar do servidor, esvaziar a lixeira.

## Telas da web (somente leitura)
- **Login**.
- **Biblioteca**: igual à do tablet, sem criar, editar ou excluir. Mostra "Editado agora" nos cadernos alterados há poucos minutos.
- **Visualizador**: páginas em coluna com zoom (botões, Ctrl+roda, pinça no celular), barra lateral de miniaturas e marcadores, botão **"Seguir tablet"**, botão **Baixar PDF**, indicador "ao vivo" (bolinha verde quando o tablet está escrevendo).
- Responsivo: funciona no computador e no celular.
