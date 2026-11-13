# 01 — Arquitetura

## Visão
```
┌──────────────── app/ (Flutter, um código só) ─────────────────┐
│                                                                │
│  Android (Tab S7) — MODO EDITOR      Web — MODO VISUALIZADOR   │
│  ┌────────────────────────────┐      ┌──────────────────────┐  │
│  │ features/editor            │      │ features/viewer      │  │
│  │ features/library           │      │ features/library (RO)│  │
│  │ data/local (Drift/SQLite)  │      │ data/remote (leitura)│  │
│  │ data/sync (outbox)         │      │ realtime (assina)    │  │
│  └─────────────┬──────────────┘      └──────────┬───────────┘  │
│        shared/render + core  (mesmo desenho dos dois lados)    │
└────────────────┼────────────────────────────────┼──────────────┘
                 │ escreve (upsert) + broadcast   │ lê + assina
                 ▼                                ▼
        ┌──────────────── Supabase ─────────────────┐
        │ Auth · Postgres (RLS) · Realtime · Storage │
        └────────────────────────────────────────────┘
```

## Por que Flutter
- Uma linguagem e um projeto para o tablet e para a web: menos coisa para configurar e manter.
- O **mesmo código de desenho** roda nos dois lados, então a web mostra exatamente o que foi escrito no tablet.
- O Flutter recebe da S Pen o tipo de ponteiro (`PointerDeviceKind.stylus`), a pressão, a inclinação e os botões. Na tela de 120 Hz, a latência é adequada para uso pessoal.

## Pacotes (versões estáveis mais recentes na hora da criação)
| Uso | Pacote |
|---|---|
| Estado | `flutter_riverpod` |
| Rotas | `go_router` |
| Supabase | `supabase_flutter` |
| Banco local | `drift`, `drift_flutter`, `sqlite3_flutter_libs`, `path_provider` (dev: `drift_dev`, `build_runner`) |
| Traços | `perfect_freehand` |
| IDs | `uuid` (v4) |
| Sincronização em segundo plano | `connectivity_plus` (o sincronizador roda enquanto o app está aberto; não precisa de WorkManager) |
| PDF (exibir) | `pdfrx` (Android e web) |
| PDF (exportar) | `pdf` |
| Imagens | `image_picker`, `image` (redimensionar/comprimir) |
| Arquivos | `file_picker`, `share_plus` só para "salvar como" no Android (sem compartilhar com terceiros) |
| Reconhecimento de escrita (fase 6) | `google_mlkit_digital_ink_recognition` |
| Testes | `flutter_test`, `mocktail` |

O agente pode trocar um pacote se ele estiver abandonado ou não funcionar, mas deve registrar a troca aqui.

## Modos de execução
```dart
// main.dart (ideia)
if (kIsWeb) runApp(ViewerApp());   // sem Drift, sem ferramentas
else        runApp(EditorApp());   // Drift + sync + editor
```
- Na web, os repositórios leem direto do Supabase.
- No Android, a interface lê **só do Drift**. O sincronizador envia o conteúdo do Drift para o Supabase em segundo plano.

## Camadas
1. **core/**: modelos imutáveis (`Folder`, `Notebook`, `Page`, `Stroke`, `Element`), `PageSize`, `PointCodec`, geometria (bbox, interseções, transformações), reconhecimento de formas, régua. Dart puro, 100% testável.
2. **shared/render/**: `PagePainter` (fundo + PDF + marca-texto + tinta + elementos), `StrokeRenderer` (perfect_freehand → `Path`), cache de traços em `ui.Picture`.
3. **data/**: `local/` (Drift), `remote/` (Supabase), `sync/`.
4. **features/**: telas e controladores (Riverpod `Notifier`).

## Segurança
- Um usuário: cadastro público **desativado** no Supabase depois de criar a conta.
- **RLS** em todas as tabelas: `user_id = auth.uid()`.
- Bucket `assets` privado; caminho `{user_id}/...`; políticas de Storage pelo prefixo.
- Só a *anon key* entra no app. A *service role key* **nunca** entra.

## Publicação
- **Android**: APK instalado direto no tablet (`flutter install` ou arquivo .apk). Sem Play Store.
- **Web**: `flutter build web` → **Cloudflare Pages**, Netlify ou Vercel (grátis). Passo a passo em `docs/07`.
