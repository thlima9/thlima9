-- Th Notes — esquema inicial
-- Rode inteiro no SQL Editor do Supabase (uma vez).
-- Convenções: ids gerados no tablet (uuid), exclusão lógica (deleted_at), coordenadas em unidades de página (1 u = 1/72").

-- ───────────────────────── Função utilitária ─────────────────────────
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

-- ───────────────────────── Tabelas ─────────────────────────
create table public.folder (
  id          uuid primary key,
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  parent_id   uuid references public.folder(id) on delete cascade,
  name        text not null,
  sort_index  double precision not null default 0,
  is_favorite boolean not null default false,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

create table public.notebook (
  id                  uuid primary key,
  user_id             uuid not null default auth.uid() references auth.users(id) on delete cascade,
  folder_id           uuid references public.folder(id) on delete set null,
  title               text not null,
  cover               jsonb not null default '{}'::jsonb,
  default_page_size   text not null default 'tab_s7_landscape',
  default_template    text not null default 'blank',
  default_paper_color text not null default 'white',
  scroll_direction    text not null default 'vertical' check (scroll_direction in ('vertical','horizontal')),
  sort_index          double precision not null default 0,
  is_favorite         boolean not null default false,
  last_opened_at      timestamptz,
  thumbnail_path      text,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  deleted_at          timestamptz
);

create table public.asset (
  id           uuid primary key,
  user_id      uuid not null default auth.uid() references auth.users(id) on delete cascade,
  kind         text not null check (kind in ('pdf','image')),
  storage_path text not null,
  sha256       text,
  byte_size    bigint,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  deleted_at   timestamptz
);

create table public.page (
  id              uuid primary key,
  user_id         uuid not null default auth.uid() references auth.users(id) on delete cascade,
  notebook_id     uuid not null references public.notebook(id) on delete cascade,
  sort_index      double precision not null,
  width           real not null,
  height          real not null,
  page_size       text not null,
  template        text not null default 'blank',
  paper_color     text not null default 'white',
  pdf_asset_id    uuid references public.asset(id) on delete set null,
  pdf_page_index  int,
  is_bookmarked   boolean not null default false,
  bookmark_title  text,
  thumbnail_path  text,
  recognized_text text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  deleted_at      timestamptz
);

create table public.stroke (
  id          uuid primary key,
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  page_id     uuid not null references public.page(id) on delete cascade,
  notebook_id uuid not null references public.notebook(id) on delete cascade, -- facilita filtros do realtime
  tool        text not null check (tool in ('pen_ballpoint','pen_fountain','pen_brush','highlighter','shape')),
  color       bigint not null,
  width       real not null,
  points      text not null,      -- codec v1 em base64 (docs/04)
  point_count int not null,
  bbox        real[] not null check (array_length(bbox, 1) = 4),
  z           bigint not null,
  shape       jsonb,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

create table public.element (
  id          uuid primary key,
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  page_id     uuid not null references public.page(id) on delete cascade,
  notebook_id uuid not null references public.notebook(id) on delete cascade,
  type        text not null check (type in ('text','image')),
  z           bigint not null,
  x           real not null,
  y           real not null,
  width       real not null,
  height      real not null,
  rotation    real not null default 0,
  data        jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

create table public.device_state (
  user_id          uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  open_notebook_id uuid,
  open_page_id     uuid,
  updated_at       timestamptz not null default now()
);

-- ───────────────────────── Índices ─────────────────────────
create index folder_user_idx     on public.folder   (user_id, parent_id) where deleted_at is null;
create index notebook_user_idx   on public.notebook (user_id, folder_id) where deleted_at is null;
create index page_notebook_idx   on public.page     (notebook_id, sort_index) where deleted_at is null;
create index stroke_page_idx     on public.stroke   (page_id, z) where deleted_at is null;
create index element_page_idx    on public.element  (page_id, z) where deleted_at is null;
create index stroke_updated_idx  on public.stroke   (user_id, updated_at);
create index page_updated_idx    on public.page     (user_id, updated_at);

-- ───────────────────────── updated_at automático ─────────────────────────
do $$
declare t text;
begin
  foreach t in array array['folder','notebook','asset','page','stroke','element','device_state'] loop
    execute format('create trigger %I_updated_at before update on public.%I
                    for each row execute function public.set_updated_at()', t, t);
  end loop;
end $$;

-- ───────────────────────── Segurança (RLS): só o dono ─────────────────────────
do $$
declare t text;
begin
  foreach t in array array['folder','notebook','asset','page','stroke','element','device_state'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('create policy %I_owner on public.%I for all to authenticated
                    using (user_id = auth.uid()) with check (user_id = auth.uid())', t, t);
  end loop;
end $$;

-- ───────────────────────── Realtime ─────────────────────────
alter publication supabase_realtime add table
  public.folder, public.notebook, public.page, public.stroke, public.element, public.device_state;

-- Broadcast privado (canal "live:{user_id}"): só o próprio usuário envia/recebe.
-- O cliente deve abrir o canal com config private: true.
create policy live_channel_owner_select on realtime.messages for select to authenticated
  using (realtime.topic() = 'live:' || auth.uid()::text);
create policy live_channel_owner_insert on realtime.messages for insert to authenticated
  with check (realtime.topic() = 'live:' || auth.uid()::text);

-- ───────────────────────── Storage ─────────────────────────
insert into storage.buckets (id, name, public)
values ('assets', 'assets', false), ('thumbnails', 'thumbnails', false)
on conflict (id) do nothing;

-- Arquivos ficam em "{user_id}/..." — cada usuário só acessa a própria pasta.
create policy storage_owner_select on storage.objects for select to authenticated
  using (bucket_id in ('assets','thumbnails') and (storage.foldername(name))[1] = auth.uid()::text);
create policy storage_owner_insert on storage.objects for insert to authenticated
  with check (bucket_id in ('assets','thumbnails') and (storage.foldername(name))[1] = auth.uid()::text);
create policy storage_owner_update on storage.objects for update to authenticated
  using (bucket_id in ('assets','thumbnails') and (storage.foldername(name))[1] = auth.uid()::text);
create policy storage_owner_delete on storage.objects for delete to authenticated
  using (bucket_id in ('assets','thumbnails') and (storage.foldername(name))[1] = auth.uid()::text);
