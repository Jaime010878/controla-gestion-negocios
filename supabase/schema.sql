-- CONTROL A / Controla: esquema inicial multi-negocio con aislamiento por RLS
create extension if not exists pgcrypto;
create table if not exists public.businesses (
 id uuid primary key default gen_random_uuid(),
 name text not null,
 business_type text not null default 'general',
 created_at timestamptz not null default now()
);
create table if not exists public.business_members (
 business_id uuid not null references public.businesses(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 role text not null default 'owner' check (role in ('owner','manager','staff')),
 created_at timestamptz not null default now(),
 primary key (business_id,user_id)
);
create or replace function public.is_business_member(p_business_id uuid)
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.business_members m where m.business_id=p_business_id and m.user_id=auth.uid()); $$;
create or replace function public.create_business(p_name text,p_business_type text default 'general')
returns public.businesses language plpgsql security definer set search_path=public
as $$ declare b public.businesses; begin
 if auth.uid() is null then raise exception 'Debes iniciar sesión'; end if;
 insert into public.businesses(name,business_type) values(trim(p_name),coalesce(nullif(p_business_type,''),'general')) returning * into b;
 insert into public.business_members(business_id,user_id,role) values(b.id,auth.uid(),'owner');
 return b;
end; $$;
create table if not exists public.products (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
 name text not null, sku text, quantity numeric(14,3) not null default 0 check(quantity>=0),
 cost numeric(14,2) not null default 0 check(cost>=0), price numeric(14,2) not null default 0 check(price>=0),
 min_stock numeric(14,3) not null default 3, created_at timestamptz not null default now()
);
create table if not exists public.sales (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
 product_id uuid references public.products(id) on delete set null, description text, quantity numeric(14,3) not null default 1,
 amount numeric(14,2) not null check(amount>=0), cost_total numeric(14,2) not null default 0,
 payment_method text not null default 'Efectivo', occurred_at date not null default current_date, created_at timestamptz not null default now()
);
create table if not exists public.expenses (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
 description text not null, category text not null default 'Otros', amount numeric(14,2) not null check(amount>=0),
 occurred_at date not null default current_date, receipt_path text, created_at timestamptz not null default now()
);
create table if not exists public.staff (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
 name text not null, commission_percent numeric(5,2) not null default 0 check(commission_percent between 0 and 100), created_at timestamptz not null default now()
);
create table if not exists public.services (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
 name text not null, price numeric(14,2) not null default 0, created_at timestamptz not null default now()
);
create table if not exists public.service_records (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
 staff_id uuid references public.staff(id) on delete set null, service_id uuid references public.services(id) on delete set null,
 amount numeric(14,2) not null default 0, commission_amount numeric(14,2) not null default 0,
 occurred_at date not null default current_date, created_at timestamptz not null default now()
);
alter table public.businesses enable row level security;
alter table public.business_members enable row level security;
alter table public.products enable row level security;
alter table public.sales enable row level security;
alter table public.expenses enable row level security;
alter table public.staff enable row level security;
alter table public.services enable row level security;
alter table public.service_records enable row level security;
drop policy if exists "members read businesses" on public.businesses;
create policy "members read businesses" on public.businesses for select to authenticated using(public.is_business_member(id));
drop policy if exists "members read memberships" on public.business_members;
create policy "members read memberships" on public.business_members for select to authenticated using(user_id=auth.uid() or public.is_business_member(business_id));
do $$ declare t text; begin
 foreach t in array array['products','sales','expenses','staff','services','service_records'] loop
  execute format('drop policy if exists %I on public.%I',t||'_member_access',t);
  execute format('create policy %I on public.%I for all to authenticated using(public.is_business_member(business_id)) with check(public.is_business_member(business_id))',t||'_member_access',t);
 end loop;
end $$;
grant execute on function public.create_business(text,text) to authenticated;
grant execute on function public.is_business_member(uuid) to authenticated;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('receipts','receipts',false,10485760,array['image/jpeg','image/png','image/webp','application/pdf'])
on conflict(id) do nothing;
drop policy if exists "members upload receipt files" on storage.objects;
create policy "members upload receipt files" on storage.objects for insert to authenticated
with check(bucket_id='receipts' and public.is_business_member(((storage.foldername(name))[1])::uuid));
drop policy if exists "members read receipt files" on storage.objects;
create policy "members read receipt files" on storage.objects for select to authenticated
using(bucket_id='receipts' and public.is_business_member(((storage.foldername(name))[1])::uuid));
drop policy if exists "members delete receipt files" on storage.objects;
create policy "members delete receipt files" on storage.objects for delete to authenticated
using(bucket_id='receipts' and public.is_business_member(((storage.foldername(name))[1])::uuid));
create index if not exists products_business_idx on public.products(business_id);
create index if not exists sales_business_date_idx on public.sales(business_id,occurred_at);
create index if not exists expenses_business_date_idx on public.expenses(business_id,occurred_at);
create index if not exists service_records_business_date_idx on public.service_records(business_id,occurred_at);
