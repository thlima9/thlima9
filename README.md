# Th Notes

App pessoal de anotações à mão, no estilo GoodNotes, para o **Samsung Galaxy Tab S7** com S Pen. Tudo o que é escrito no tablet aparece **ao vivo em uma página web** (só para visualização).

## Como funciona

```
 Tab S7 (app Flutter Android)  ──►  Supabase (banco + tempo real + arquivos)  ──►  Navegador (app Flutter Web)
   escreve, organiza, offline         guarda tudo, avisa mudanças                    só visualiza, ao vivo
```

- **Um projeto Flutter** (`app/`) gera os dois apps: o Android e o Web. O modo é escolhido automaticamente (Web = visualizador).
- **Supabase gerenciado** (plano gratuito) cuida do login, do banco de dados, do tempo real e dos PDFs e imagens.

## Estrutura do repositório

| Caminho | O que é |
|---|---|
| `CLAUDE.md` | Regras e contexto para a IA que escreve o código (Fable/Claude Code) |
| `docs/00-visao-geral.md` | Escopo e funcionalidades |
| `docs/01-arquitetura.md` | Tecnologias, pacotes e organização do código |
| `docs/02-modelo-de-dados.md` | Tabelas, entidades e tamanhos de página |
| `docs/03-sincronizacao.md` | Como tablet → Supabase → web funciona |
| `docs/04-tinta-e-renderizacao.md` | Formato dos traços, ferramentas, desenho |
| `docs/05-interface.md` | Telas, barra de ferramentas e gestos |
| `docs/06-roteiro.md` | **Fases com tarefas e critérios de aceite (checklist)** |
| `docs/07-configuracao.md` | Passo a passo: instalar Flutter, criar Supabase, rodar no tablet, publicar a web |
| `prompts/` | Prompts prontos para pedir cada fase ao Fable |
| `supabase/migrations/` | SQL do banco (tabelas, segurança, tempo real) |
| `app/` | Código Flutter (criado na Fase 0) |

## Por onde começar
1. Siga `docs/07-configuracao.md` (instalações e conta no Supabase).
2. Abra uma sessão com o Fable neste repositório e cole `prompts/fase-0.md`.
3. Siga as fases em ordem, conferindo o checklist em `docs/06-roteiro.md`.
