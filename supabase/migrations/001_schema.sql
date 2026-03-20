-- ============================================================
-- Securitas ISMS/AIMS Portal - Supabase Schema
-- ============================================================

-- ---- プロファイルテーブル (auth.users の拡張) ----
create table if not exists public.profiles (
  id          uuid references auth.users(id) on delete cascade primary key,
  display_name text,
  dept        text,
  role        text not null default 'user' check (role in ('admin', 'user')),
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

-- RLS 有効化
alter table public.profiles enable row level security;

-- 認証済みユーザーは全プロファイルを参照可能
create policy "authenticated_read_profiles"
  on public.profiles for select
  to authenticated
  using (true);

-- ユーザーは自分のプロファイルを更新可能
create policy "user_update_own_profile"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id);

-- 管理者は全プロファイルを更新可能
create policy "admin_update_all_profiles"
  on public.profiles for update
  to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

-- ユーザー登録時に自動でプロファイルを作成するトリガー
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, display_name, dept, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'dept', '未設定'),
    coalesce(new.raw_user_meta_data->>'role', 'user')
  );
  return new;
end;
$$ language plpgsql security definer;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ---- 組織データテーブル (アプリ全体の共有状態) ----
create table if not exists public.org_data (
  key         text primary key,
  value       jsonb not null default '{}',
  updated_at  timestamptz default now(),
  updated_by  uuid references auth.users(id)
);

alter table public.org_data enable row level security;

-- 認証済みユーザーは読み取り可能
create policy "authenticated_read_org_data"
  on public.org_data for select
  to authenticated
  using (true);

-- 認証済みユーザーは書き込み可能
create policy "authenticated_insert_org_data"
  on public.org_data for insert
  to authenticated
  with check (true);

create policy "authenticated_update_org_data"
  on public.org_data for update
  to authenticated
  using (true);

-- ---- updated_at 自動更新 ----
create or replace function public.update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger profiles_updated_at
  before update on public.profiles
  for each row execute procedure public.update_updated_at();

create trigger org_data_updated_at
  before update on public.org_data
  for each row execute procedure public.update_updated_at();
