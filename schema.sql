-- ╔══════════════════════════════════════╗
-- ║  FLEXBOR CRM — Schema limpo          ║
-- ║  Sem RLS, sem triggers complexos     ║
-- ╚══════════════════════════════════════╝

-- Perfis (ligado ao auth.users)
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  nome text not null,
  role text not null default 'comercial',
  created_at timestamptz default now()
);

-- Clientes
create table public.clientes (
  id uuid default gen_random_uuid() primary key,
  nome text not null,
  setor text,
  contacto text,
  tel text,
  email text,
  morada text,
  notas text,
  criado_por uuid references public.profiles(id),
  created_at timestamptz default now()
);

-- Visitas
create table public.visitas (
  id uuid default gen_random_uuid() primary key,
  data date not null,
  tipo text not null default 'Presencial',
  cliente_id uuid references public.clientes(id) on delete set null,
  cliente_nome text,
  objetivo text,
  notas text,
  proximo_passo text,
  criado_por uuid references public.profiles(id),
  created_at timestamptz default now()
);

-- Oportunidades
create table public.oportunidades (
  id uuid default gen_random_uuid() primary key,
  nome text not null,
  cliente_id uuid references public.clientes(id) on delete set null,
  cliente_nome text,
  valor numeric default 0,
  probabilidade int default 50,
  fase text not null default 'Prospeção',
  data_fecho date,
  notas text,
  estado text default 'aberta',
  criado_por uuid references public.profiles(id),
  created_at timestamptz default now()
);

-- Tarefas
create table public.tarefas (
  id uuid default gen_random_uuid() primary key,
  descricao text not null,
  cliente_id uuid references public.clientes(id) on delete set null,
  cliente_nome text,
  tipo text default 'Follow-up',
  data_limite date,
  notas text,
  estado text default 'pendente',
  criado_por uuid references public.profiles(id),
  created_at timestamptz default now()
);

-- Trigger simples: cria perfil automaticamente ao registar utilizador
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, nome, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'nome', split_part(new.email,'@',1)),
    coalesce(new.raw_user_meta_data->>'role', 'comercial')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Sem RLS — acesso controlado pela aplicação
-- O gestor vê tudo, o comercial filtra por criado_por no código
