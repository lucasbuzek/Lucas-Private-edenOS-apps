-- HERMES v1.3 secure application schema
create extension if not exists pgcrypto;

create table if not exists public.profiles (
 user_id uuid primary key references auth.users(id) on delete cascade,
 display_name text, active_mode text not null default 'PERSON' check(active_mode in ('PERSON','COMPANY','HYBRID')),
 candidate_truth jsonb not null default '{}'::jsonb, company_truth jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now());

create table if not exists public.saved_searches (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 mode text not null default 'PERSON', name text not null, query text not null, filters jsonb not null default '{}'::jsonb,
 enabled boolean not null default true, cadence text not null default 'MANUAL', last_run_at timestamptz,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now());

create table if not exists public.opportunities (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 kind text not null check(kind in ('JOB','TENDER','CONTRACT','FREELANCE','OTHER')), title text not null,
 organization text, location text, canonical_url text, source text, source_id text, original_text text,
 normalized jsonb not null default '{}'::jsonb, match_summary text, match_score numeric,
 status text not null default 'DISCOVERED', deadline timestamptz, discovered_at timestamptz not null default now(),
 updated_at timestamptz not null default now(), created_at timestamptz not null default now(),
 unique(user_id, source, source_id));

create table if not exists public.documents (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 opportunity_id uuid references public.opportunities(id) on delete set null, kind text not null, title text not null,
 variant text, storage_path text, content_text text, metadata jsonb not null default '{}'::jsonb,
 frozen boolean not null default false, created_at timestamptz not null default now(), updated_at timestamptz not null default now());

create table if not exists public.compliance_items (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 entity text not null default 'COMPANY', doc_type text not null, issuer text, issue_date date, expiry_date date,
 status text not null default 'UNKNOWN', storage_path text, metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now());

create table if not exists public.agent_runs (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 saved_search_id uuid references public.saved_searches(id) on delete set null, state text not null default 'QUEUED',
 started_at timestamptz, finished_at timestamptz, summary jsonb not null default '{}'::jsonb,
 error text, created_at timestamptz not null default now());

create table if not exists public.events (
 id bigint generated always as identity primary key, user_id uuid not null references auth.users(id) on delete cascade,
 opportunity_id uuid references public.opportunities(id) on delete cascade, event_type text not null,
 payload jsonb not null default '{}'::jsonb, created_at timestamptz not null default now());

alter table public.profiles enable row level security; alter table public.saved_searches enable row level security;
alter table public.opportunities enable row level security; alter table public.documents enable row level security;
alter table public.compliance_items enable row level security; alter table public.agent_runs enable row level security;
alter table public.events enable row level security;

do $$ declare t text; begin foreach t in array array['profiles','saved_searches','opportunities','documents','compliance_items','agent_runs','events'] loop
 execute format('drop policy if exists "own rows" on public.%I',t);
 execute format('create policy "own rows" on public.%I for all using (auth.uid() = user_id) with check (auth.uid() = user_id)',t);
end loop; end $$;

create index if not exists opportunities_user_status_idx on public.opportunities(user_id,status);
create index if not exists opportunities_user_deadline_idx on public.opportunities(user_id,deadline);
create index if not exists saved_searches_user_enabled_idx on public.saved_searches(user_id,enabled);
create index if not exists documents_user_kind_idx on public.documents(user_id,kind);
create index if not exists compliance_user_expiry_idx on public.compliance_items(user_id,expiry_date);
create index if not exists agent_runs_user_created_idx on public.agent_runs(user_id,created_at desc);
create index if not exists events_user_created_idx on public.events(user_id,created_at desc);
