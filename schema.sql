-- Flexbor CRM
-- Supabase bootstrap + security policies

create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nome text not null,
  role text not null default 'comercial',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.clientes (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  setor text,
  tel text,
  morada text,
  notas text,
  criado_por uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.contactos (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid not null references public.clientes(id) on delete cascade,
  nome text not null,
  cargo text,
  tel text,
  email text,
  notas text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.visitas (
  id uuid primary key default gen_random_uuid(),
  data date not null,
  tipo text not null default 'Presencial',
  cliente_id uuid references public.clientes(id) on delete set null,
  cliente_nome text,
  objetivo text,
  notas text,
  proximo_passo text,
  contacto_id uuid references public.contactos(id) on delete set null,
  criado_por uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.oportunidades (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  cliente_id uuid references public.clientes(id) on delete set null,
  cliente_nome text,
  valor numeric not null default 0,
  probabilidade integer not null default 50,
  fase text not null default 'Prospeccao',
  data_fecho date,
  notas text,
  estado text not null default 'aberta',
  criado_por uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.tarefas (
  id uuid primary key default gen_random_uuid(),
  descricao text not null,
  cliente_id uuid references public.clientes(id) on delete set null,
  cliente_nome text,
  tipo text not null default 'Follow-up',
  data_limite date,
  notas text,
  estado text not null default 'pendente',
  criado_por uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles
  alter column role set default 'comercial';

alter table public.profiles add column if not exists updated_at timestamptz not null default now();
alter table public.clientes add column if not exists updated_at timestamptz not null default now();
alter table public.contactos add column if not exists updated_at timestamptz not null default now();
alter table public.visitas add column if not exists updated_at timestamptz not null default now();
alter table public.oportunidades add column if not exists updated_at timestamptz not null default now();
alter table public.tarefas add column if not exists updated_at timestamptz not null default now();

alter table public.clientes
  drop column if exists contacto,
  drop column if exists email;

alter table public.visitas
  add column if not exists contacto_id uuid references public.contactos(id) on delete set null;

alter table public.oportunidades
  alter column valor set default 0,
  alter column probabilidade set default 50,
  alter column estado set default 'aberta';

alter table public.tarefas
  alter column tipo set default 'Follow-up',
  alter column estado set default 'pendente';

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'profiles_role_check'
  ) then
    alter table public.profiles
      add constraint profiles_role_check
      check (role in ('comercial', 'gestor'));
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'visitas_tipo_check'
  ) then
    alter table public.visitas
      add constraint visitas_tipo_check
      check (tipo in ('Presencial', 'Videochamada', 'Telefone'));
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'oportunidades_estado_check'
  ) then
    alter table public.oportunidades
      add constraint oportunidades_estado_check
      check (estado in ('aberta', 'ganha', 'perdida'));
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'oportunidades_valor_check'
  ) then
    alter table public.oportunidades
      add constraint oportunidades_valor_check
      check (valor >= 0);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'oportunidades_probabilidade_check'
  ) then
    alter table public.oportunidades
      add constraint oportunidades_probabilidade_check
      check (probabilidade between 0 and 100);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'tarefas_estado_check'
  ) then
    alter table public.tarefas
      add constraint tarefas_estado_check
      check (estado in ('pendente', 'concluida'));
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'contactos_email_check'
  ) then
    alter table public.contactos
      add constraint contactos_email_check
      check (email is null or position('@' in email) > 1);
  end if;
end $$;

create index if not exists idx_profiles_role on public.profiles(role);
create index if not exists idx_clientes_criado_por on public.clientes(criado_por);
create index if not exists idx_contactos_cliente_id on public.contactos(cliente_id);
create index if not exists idx_visitas_criado_por_data on public.visitas(criado_por, data desc);
create index if not exists idx_visitas_data on public.visitas(data desc);
create index if not exists idx_visitas_cliente_id on public.visitas(cliente_id);
create index if not exists idx_visitas_contacto_id on public.visitas(contacto_id);
create index if not exists idx_oportunidades_criado_por_estado on public.oportunidades(criado_por, estado);
create index if not exists idx_oportunidades_cliente_id on public.oportunidades(cliente_id);
create index if not exists idx_oportunidades_data_fecho on public.oportunidades(data_fecho);
create index if not exists idx_oportunidades_abertas_fecho on public.oportunidades(criado_por, data_fecho) where estado = 'aberta';
create index if not exists idx_tarefas_criado_por_estado_data on public.tarefas(criado_por, estado, data_limite);
create index if not exists idx_tarefas_cliente_id on public.tarefas(cliente_id);
create index if not exists idx_tarefas_pendentes_data on public.tarefas(criado_por, data_limite) where estado = 'pendente';

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, nome, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'nome', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data ->> 'role', 'comercial')
  )
  on conflict (id) do update
  set
    nome = excluded.nome,
    role = excluded.role;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.sync_cliente_denormalized_fields()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.visitas
  set cliente_nome = new.nome
  where cliente_id = new.id
    and cliente_nome is distinct from new.nome;

  update public.oportunidades
  set cliente_nome = new.nome
  where cliente_id = new.id
    and cliente_nome is distinct from new.nome;

  update public.tarefas
  set cliente_nome = new.nome
  where cliente_id = new.id
    and cliente_nome is distinct from new.nome;

  return new;
end;
$$;

create or replace function public.prepare_visita()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  cliente_nome_value text;
  contacto_cliente_id uuid;
begin
  if new.cliente_id is not null then
    select nome into cliente_nome_value
    from public.clientes
    where id = new.cliente_id;

    new.cliente_nome = cliente_nome_value;
  else
    new.cliente_nome = null;
  end if;

  if new.contacto_id is not null then
    select cliente_id into contacto_cliente_id
    from public.contactos
    where id = new.contacto_id;

    if contacto_cliente_id is null then
      raise exception 'Contacto inválido para a visita.';
    end if;

    if new.cliente_id is distinct from contacto_cliente_id then
      raise exception 'O contacto selecionado não pertence ao cliente da visita.';
    end if;
  end if;

  return new;
end;
$$;

create or replace function public.prepare_oportunidade()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.cliente_id is not null then
    select nome into new.cliente_nome
    from public.clientes
    where id = new.cliente_id;
  else
    new.cliente_nome = null;
  end if;

  return new;
end;
$$;

create or replace function public.prepare_tarefa()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.cliente_id is not null then
    select nome into new.cliente_nome
    from public.clientes
    where id = new.cliente_id;
  else
    new.cliente_nome = null;
  end if;

  return new;
end;
$$;

create or replace function public.current_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select p.role
  from public.profiles p
  where p.id = auth.uid()
$$;

create or replace function public.can_access_cliente(target_cliente uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.clientes c
    where c.id = target_cliente
      and (
        c.criado_por = auth.uid()
        or public.current_role() = 'gestor'
      )
  )
$$;

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
  before update on public.profiles
  for each row execute procedure public.set_updated_at();

drop trigger if exists set_clientes_updated_at on public.clientes;
create trigger set_clientes_updated_at
  before update on public.clientes
  for each row execute procedure public.set_updated_at();

drop trigger if exists set_contactos_updated_at on public.contactos;
create trigger set_contactos_updated_at
  before update on public.contactos
  for each row execute procedure public.set_updated_at();

drop trigger if exists set_visitas_updated_at on public.visitas;
create trigger set_visitas_updated_at
  before update on public.visitas
  for each row execute procedure public.set_updated_at();

drop trigger if exists set_oportunidades_updated_at on public.oportunidades;
create trigger set_oportunidades_updated_at
  before update on public.oportunidades
  for each row execute procedure public.set_updated_at();

drop trigger if exists set_tarefas_updated_at on public.tarefas;
create trigger set_tarefas_updated_at
  before update on public.tarefas
  for each row execute procedure public.set_updated_at();

drop trigger if exists sync_cliente_denormalized_fields_trigger on public.clientes;
create trigger sync_cliente_denormalized_fields_trigger
  after update of nome on public.clientes
  for each row execute procedure public.sync_cliente_denormalized_fields();

drop trigger if exists prepare_visita_trigger on public.visitas;
create trigger prepare_visita_trigger
  before insert or update on public.visitas
  for each row execute procedure public.prepare_visita();

drop trigger if exists prepare_oportunidade_trigger on public.oportunidades;
create trigger prepare_oportunidade_trigger
  before insert or update on public.oportunidades
  for each row execute procedure public.prepare_oportunidade();

drop trigger if exists prepare_tarefa_trigger on public.tarefas;
create trigger prepare_tarefa_trigger
  before insert or update on public.tarefas
  for each row execute procedure public.prepare_tarefa();

grant usage on schema public to authenticated;

grant select, insert, update, delete on public.profiles to authenticated;
grant select, insert, update, delete on public.clientes to authenticated;
grant select, insert, update, delete on public.contactos to authenticated;
grant select, insert, update, delete on public.visitas to authenticated;
grant select, insert, update, delete on public.oportunidades to authenticated;
grant select, insert, update, delete on public.tarefas to authenticated;

alter table public.profiles enable row level security;
alter table public.clientes enable row level security;
alter table public.contactos enable row level security;
alter table public.visitas enable row level security;
alter table public.oportunidades enable row level security;
alter table public.tarefas enable row level security;

drop policy if exists "profiles_select_self_or_manager" on public.profiles;
create policy "profiles_select_self_or_manager"
on public.profiles
for select
using (id = auth.uid() or public.current_role() = 'gestor');

drop policy if exists "profiles_update_self_or_manager" on public.profiles;
create policy "profiles_update_self_or_manager"
on public.profiles
for update
using (id = auth.uid() or public.current_role() = 'gestor')
with check (
  public.current_role() = 'gestor'
  or (
    id = auth.uid()
    and role = public.current_role()
  )
);

drop policy if exists "clientes_select" on public.clientes;
create policy "clientes_select"
on public.clientes
for select
using (criado_por = auth.uid() or public.current_role() = 'gestor');

drop policy if exists "clientes_insert" on public.clientes;
create policy "clientes_insert"
on public.clientes
for insert
with check (criado_por = auth.uid() or public.current_role() = 'gestor');

drop policy if exists "clientes_update" on public.clientes;
create policy "clientes_update"
on public.clientes
for update
using (criado_por = auth.uid() or public.current_role() = 'gestor')
with check (criado_por = auth.uid() or public.current_role() = 'gestor');

drop policy if exists "clientes_delete" on public.clientes;
create policy "clientes_delete"
on public.clientes
for delete
using (criado_por = auth.uid() or public.current_role() = 'gestor');

drop policy if exists "contactos_select" on public.contactos;
create policy "contactos_select"
on public.contactos
for select
using (public.can_access_cliente(cliente_id));

drop policy if exists "contactos_insert" on public.contactos;
create policy "contactos_insert"
on public.contactos
for insert
with check (public.can_access_cliente(cliente_id));

drop policy if exists "contactos_update" on public.contactos;
create policy "contactos_update"
on public.contactos
for update
using (public.can_access_cliente(cliente_id))
with check (public.can_access_cliente(cliente_id));

drop policy if exists "contactos_delete" on public.contactos;
create policy "contactos_delete"
on public.contactos
for delete
using (public.can_access_cliente(cliente_id));

drop policy if exists "visitas_select" on public.visitas;
create policy "visitas_select"
on public.visitas
for select
using (criado_por = auth.uid() or public.current_role() = 'gestor');

drop policy if exists "visitas_insert" on public.visitas;
create policy "visitas_insert"
on public.visitas
for insert
with check (criado_por = auth.uid() or public.current_role() = 'gestor');

drop policy if exists "visitas_update" on public.visitas;
create policy "visitas_update"
on public.visitas
for update
using (criado_por = auth.uid() or public.current_role() = 'gestor')
with check (criado_por = auth.uid() or public.current_role() = 'gestor');

drop policy if exists "visitas_delete" on public.visitas;
create policy "visitas_delete"
on public.visitas
for delete
using (criado_por = auth.uid() or public.current_role() = 'gestor');

drop policy if exists "oportunidades_select" on public.oportunidades;
create policy "oportunidades_select"
on public.oportunidades
for select
using (criado_por = auth.uid() or public.current_role() = 'gestor');

drop policy if exists "oportunidades_insert" on public.oportunidades;
create policy "oportunidades_insert"
on public.oportunidades
for insert
with check (criado_por = auth.uid() or public.current_role() = 'gestor');

drop policy if exists "oportunidades_update" on public.oportunidades;
create policy "oportunidades_update"
on public.oportunidades
for update
using (criado_por = auth.uid() or public.current_role() = 'gestor')
with check (criado_por = auth.uid() or public.current_role() = 'gestor');

drop policy if exists "oportunidades_delete" on public.oportunidades;
create policy "oportunidades_delete"
on public.oportunidades
for delete
using (criado_por = auth.uid() or public.current_role() = 'gestor');

drop policy if exists "tarefas_select" on public.tarefas;
create policy "tarefas_select"
on public.tarefas
for select
using (criado_por = auth.uid() or public.current_role() = 'gestor');

drop policy if exists "tarefas_insert" on public.tarefas;
create policy "tarefas_insert"
on public.tarefas
for insert
with check (criado_por = auth.uid() or public.current_role() = 'gestor');

drop policy if exists "tarefas_update" on public.tarefas;
create policy "tarefas_update"
on public.tarefas
for update
using (criado_por = auth.uid() or public.current_role() = 'gestor')
with check (criado_por = auth.uid() or public.current_role() = 'gestor');

drop policy if exists "tarefas_delete" on public.tarefas;
create policy "tarefas_delete"
on public.tarefas
for delete
using (criado_por = auth.uid() or public.current_role() = 'gestor');

do $$
begin
  if exists (
    select 1
    from pg_publication
    where pubname = 'supabase_realtime'
  ) then
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'profiles'
    ) then
      alter publication supabase_realtime add table public.profiles;
    end if;

    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'clientes'
    ) then
      alter publication supabase_realtime add table public.clientes;
    end if;

    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'contactos'
    ) then
      alter publication supabase_realtime add table public.contactos;
    end if;

    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'visitas'
    ) then
      alter publication supabase_realtime add table public.visitas;
    end if;

    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'oportunidades'
    ) then
      alter publication supabase_realtime add table public.oportunidades;
    end if;

    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'tarefas'
    ) then
      alter publication supabase_realtime add table public.tarefas;
    end if;
  end if;
end $$;
