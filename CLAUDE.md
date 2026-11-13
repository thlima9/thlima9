# CLAUDE.md — Th Notes

Instruções para o agente de IA que desenvolve este projeto. Leia antes de qualquer tarefa.

## Contexto
- Projeto **pessoal**, de um único usuário, que **não programa**. Ele testa no tablet e na web e descreve o que vê.
- Responda e documente **em português**. Código, nomes de arquivos e identificadores ficam em **inglês**.
- Explique o que fez em linguagem simples ao final de cada tarefa, incluindo **como testar** (comandos exatos).

## Produto
App de notas manuscritas estilo GoodNotes para o **Samsung Galaxy Tab S7** (Android, tela 2560×1600, 16:10, S Pen com pressão).
Tudo é sincronizado com o **Supabase**, e um **visualizador web somente leitura** mostra os cadernos ao vivo.
Detalhes: `docs/00-visao-geral.md` e os demais arquivos em `docs/`.

## Decisões fixas (não mude sem o usuário pedir)
- **Flutter (Dart)**, um projeto só em `app/`, com alvos **android** e **web**. Sem iOS/desktop.
- `kIsWeb == true` → abre o **modo visualizador** (sem ferramentas de edição). No Android → modo editor.
- Backend: **Supabase gerenciado** (Auth, Postgres, Realtime, Storage). Nenhum servidor próprio.
- Estado: **Riverpod** (`flutter_riverpod`, sem geração de código). Rotas: **go_router**.
- Banco local (só Android): **Drift** (SQLite). O banco local é a fonte da verdade no tablet.
- Traços: pacote **`perfect_freehand`**, usado igualmente no tablet e na web (fidelidade visual).
- Formato de traço, tamanhos de página e protocolo de sincronização seguem **exatamente** `docs/02`, `docs/03` e `docs/04`.
- O **tablet é o único que escreve**. A web nunca grava dados.

## Fora do escopo (não implemente)
Compartilhamento, colaboração, envio por e‑mail/link, loja de modelos, IA, gravação de áudio, stickers, iOS.

## Organização do código (`app/lib/`)
```
main.dart                 # inicialização, escolhe editor x visualizador
app/                      # router, tema, providers globais
core/                     # modelos, constantes, geometria, codificação de pontos (sem Flutter UI)
data/local/               # Drift: tabelas, DAOs
data/remote/              # Supabase: repositórios, realtime
data/sync/                # fila de saída (outbox) e sincronizador
features/auth/            # login
features/library/         # pastas, cadernos, lixeira, busca
features/editor/          # canvas, ferramentas, barra (só Android)
features/viewer/          # visualizador web
shared/render/            # pintura de página/traços (usado por editor E visualizador)
shared/widgets/
```
- `core/` e `shared/render/` **não podem** importar Drift nem Supabase.
- Código que só existe no Android (Drift, sensores) não pode ser importado pelo caminho web. Use imports condicionais ou mantenha atrás de providers.

## Regras de trabalho
1. Trabalhe **uma fase por vez** (`docs/06-roteiro.md`). Ao terminar uma tarefa, marque `[x]` no roteiro.
2. Antes de concluir: rode `flutter analyze` (zero erros) e `flutter test`. Escreva testes para `core/` (codificação de pontos, geometria, seleção, régua).
3. Rode `flutter build web` e `flutter build apk --debug` quando mexer em código compartilhado, para garantir que os dois compilam.
4. Mudanças no banco: **sempre** um novo arquivo em `supabase/migrations/` (`NNNN_descricao.sql`). Nunca edite migrações já aplicadas.
5. Segredos: a URL e a *anon key* do Supabase vêm de `--dart-define-from-file=env.json` (arquivo no `.gitignore`; existe `env.example.json`). Nunca faça commit de chaves.
6. Desempenho da caneta é prioridade: nada de I/O, rede ou `setState` da árvore inteira durante o traço. Veja `docs/04`.
7. Commits pequenos, mensagens em português.
8. Se algo no plano estiver errado ou inviável, explique e proponha uma alternativa antes de mudar a arquitetura.

## Comandos
```bash
cd app
flutter pub get
flutter run -d <id-do-tablet> --dart-define-from-file=env.json   # tablet via USB/Wi-Fi
flutter run -d chrome --dart-define-from-file=env.json           # web
flutter analyze && flutter test
flutter build apk --release --dart-define-from-file=env.json
flutter build web --release --dart-define-from-file=env.json
dart run build_runner build --delete-conflicting-outputs         # Drift
```
