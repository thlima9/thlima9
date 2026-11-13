# 07 — Configuração (passo a passo para quem não programa)

Faça uma vez, no seu computador (Windows, Mac ou Linux).

## 1. Instalar as ferramentas
1. **Flutter**: siga https://docs.flutter.dev/get-started/install, escolhendo o seu sistema e **Android** como alvo.
2. **Android Studio** (o instalador do Flutter pede): instale e abra uma vez para baixar o Android SDK.
3. **Google Chrome** (para testar a web).
4. **Git**, com este repositório clonado no seu computador.
5. No terminal, rode e resolva o que aparecer em vermelho:
```bash
flutter doctor
```

## 2. Preparar o Tab S7
1. **Configurações → Sobre o tablet → Informações de software** → toque 7 vezes em **Número de compilação** (ativa o modo desenvolvedor).
2. **Configurações → Opções do desenvolvedor** → ative **Depuração USB** (e/ou **Depuração sem fio**).
3. Ligue o tablet ao computador com cabo USB e aceite o aviso "Permitir depuração".
4. Confira se o tablet aparece:
```bash
flutter devices
```

## 3. Criar o Supabase
1. Crie uma conta em https://supabase.com e um **New project** (nome `th-notes`, região **South America (São Paulo)**, guarde a senha do banco).
2. **SQL Editor → New query**: cole todo o conteúdo de `supabase/migrations/0001_init.sql` e clique em **Run**. Repita para as próximas migrações, em ordem, quando elas existirem.
3. **Authentication → Users → Add user → Create new user**: o seu e-mail e uma senha (marque *Auto Confirm User*).
4. **Authentication → Sign In / Providers**: desative **Allow new users to sign up** (ninguém mais consegue criar conta).
5. **Project Settings → API** (ou *API Keys*): copie a **Project URL** e a chave **anon / publishable**.
6. Na pasta `app/`, copie `env.example.json` para `env.json` e cole os dois valores. **Nunca use a chave `service_role`.**

## 4. Rodar
```bash
cd app
flutter pub get
```
No tablet:
```bash
flutter run -d <id-do-tablet> --dart-define-from-file=env.json
```
Na web (abre o Chrome):
```bash
flutter run -d chrome --dart-define-from-file=env.json
```

## 5. Instalar a versão final no tablet (sem cabo depois)
```bash
flutter build apk --release --dart-define-from-file=env.json
```
O arquivo fica em `app/build/app/outputs/flutter-apk/app-release.apk`. Com o cabo ligado, instale com:
```bash
flutter install -d <id-do-tablet>
```
Ou copie o .apk para o tablet e abra (permita "instalar apps desconhecidos").

## 6. Publicar a web (Cloudflare Pages, grátis)
```bash
flutter build web --release --dart-define-from-file=env.json
```
1. Crie uma conta em https://pages.cloudflare.com → **Create → Pages → Upload assets**.
2. Envie a pasta `app/build/web`. Você recebe um endereço `https://th-notes.pages.dev`.
3. No Supabase: **Authentication → URL Configuration → Site URL** = esse endereço.
4. Para atualizar, repita o build e o upload. (Depois, o Fable pode automatizar isso com GitHub Actions.)

> A *anon key* fica visível no site publicado. Isso é normal e seguro, porque o **RLS** só deixa a sua conta ler os dados. Por isso o cadastro precisa estar desativado (passo 3.4).
