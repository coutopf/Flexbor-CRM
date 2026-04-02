-- ╔══════════════════════════════════════════════════════╗
-- ║  FLEXBOR CRM — Schema v3                             ║
-- ║  Com índices, RLS permissivo, trigger corrigido      ║
-- ╚══════════════════════════════════════════════════════╝

-- Perfis de utilizador
CREATE TABLE IF NOT EXISTS public.profiles (
  id        uuid REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  nome      text NOT NULL,
  role      text NOT NULL DEFAULT 'comercial',
  created_at timestamptz DEFAULT now()
);

-- Clientes
CREATE TABLE IF NOT EXISTS public.clientes (
  id         uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  nome       text NOT NULL,
  setor      text,
  contacto   text,
  tel        text,
  email      text,
  morada     text,
  notas      text,
  criado_por uuid REFERENCES public.profiles(id),
  created_at timestamptz DEFAULT now()
);

-- Visitas
CREATE TABLE IF NOT EXISTS public.visitas (
  id            uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  data          date NOT NULL,
  tipo          text NOT NULL DEFAULT 'Presencial',
  cliente_id    uuid REFERENCES public.clientes(id) ON DELETE SET NULL,
  cliente_nome  text,
  contacto_id   uuid,
  objetivo      text,
  notas         text,
  proximo_passo text,
  criado_por    uuid REFERENCES public.profiles(id),
  created_at    timestamptz DEFAULT now()
);

-- Oportunidades
CREATE TABLE IF NOT EXISTS public.oportunidades (
  id            uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  nome          text NOT NULL,
  cliente_id    uuid REFERENCES public.clientes(id) ON DELETE SET NULL,
  cliente_nome  text,
  valor         numeric DEFAULT 0,
  probabilidade int DEFAULT 50,
  fase          text NOT NULL DEFAULT 'Prospeção',
  data_fecho    date,
  notas         text,
  estado        text DEFAULT 'aberta',
  criado_por    uuid REFERENCES public.profiles(id),
  created_at    timestamptz DEFAULT now()
);

-- Tarefas
CREATE TABLE IF NOT EXISTS public.tarefas (
  id          uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  descricao   text NOT NULL,
  cliente_id  uuid REFERENCES public.clientes(id) ON DELETE SET NULL,
  cliente_nome text,
  tipo        text DEFAULT 'Follow-up',
  data_limite date,
  notas       text,
  estado      text DEFAULT 'pendente',
  criado_por  uuid REFERENCES public.profiles(id),
  created_at  timestamptz DEFAULT now()
);

-- Contactos
CREATE TABLE IF NOT EXISTS public.contactos (
  id         uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  cliente_id uuid REFERENCES public.clientes(id) ON DELETE CASCADE,
  nome       text NOT NULL,
  cargo      text,
  tel        text,
  email      text,
  notas      text,
  created_at timestamptz DEFAULT now()
);

-- ── ÍNDICES ─────────────────────────────────────────────
-- Acesso por comercial (queries mais frequentes)
CREATE INDEX IF NOT EXISTS idx_clientes_criado_por   ON public.clientes(criado_por);
CREATE INDEX IF NOT EXISTS idx_visitas_criado_por    ON public.visitas(criado_por);
CREATE INDEX IF NOT EXISTS idx_opps_criado_por       ON public.oportunidades(criado_por);
CREATE INDEX IF NOT EXISTS idx_tarefas_criado_por    ON public.tarefas(criado_por);

-- Filtros por cliente (joins frequentes)
CREATE INDEX IF NOT EXISTS idx_visitas_cliente       ON public.visitas(cliente_id);
CREATE INDEX IF NOT EXISTS idx_opps_cliente          ON public.oportunidades(cliente_id);
CREATE INDEX IF NOT EXISTS idx_tarefas_cliente       ON public.tarefas(cliente_id);
CREATE INDEX IF NOT EXISTS idx_contactos_cliente     ON public.contactos(cliente_id);

-- Ordenações frequentes
CREATE INDEX IF NOT EXISTS idx_clientes_nome         ON public.clientes(nome);
CREATE INDEX IF NOT EXISTS idx_visitas_data          ON public.visitas(data DESC);
CREATE INDEX IF NOT EXISTS idx_opps_estado           ON public.oportunidades(estado);
CREATE INDEX IF NOT EXISTS idx_opps_fase             ON public.oportunidades(fase);
CREATE INDEX IF NOT EXISTS idx_opps_data_fecho       ON public.oportunidades(data_fecho);
CREATE INDEX IF NOT EXISTS idx_tarefas_estado        ON public.tarefas(estado);
CREATE INDEX IF NOT EXISTS idx_tarefas_limite        ON public.tarefas(data_limite);

-- Pesquisa por nome (requer extensão pg_trgm)
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS idx_clientes_nome_trgm    ON public.clientes USING gin(nome gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_clientes_setor        ON public.clientes(setor);

-- ── RLS ─────────────────────────────────────────────────
ALTER TABLE public.profiles    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clientes    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.visitas     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.oportunidades ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tarefas     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contactos   ENABLE ROW LEVEL SECURITY;

-- Políticas permissivas (acesso controlado pela aplicação)
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='profiles' AND policyname='acesso_total') THEN
    CREATE POLICY "acesso_total" ON public.profiles FOR ALL USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='clientes' AND policyname='acesso_total') THEN
    CREATE POLICY "acesso_total" ON public.clientes FOR ALL USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='visitas' AND policyname='acesso_total') THEN
    CREATE POLICY "acesso_total" ON public.visitas FOR ALL USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='oportunidades' AND policyname='acesso_total') THEN
    CREATE POLICY "acesso_total" ON public.oportunidades FOR ALL USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='tarefas' AND policyname='acesso_total') THEN
    CREATE POLICY "acesso_total" ON public.tarefas FOR ALL USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='contactos' AND policyname='acesso_total') THEN
    CREATE POLICY "acesso_total" ON public.contactos FOR ALL USING (true) WITH CHECK (true);
  END IF;
END $$;

-- ── PERMISSÕES ──────────────────────────────────────────
GRANT ALL ON public.profiles     TO anon, authenticated;
GRANT ALL ON public.clientes     TO anon, authenticated;
GRANT ALL ON public.visitas      TO anon, authenticated;
GRANT ALL ON public.oportunidades TO anon, authenticated;
GRANT ALL ON public.tarefas      TO anon, authenticated;
GRANT ALL ON public.contactos    TO anon, authenticated;
GRANT USAGE ON SCHEMA public TO anon, authenticated;

-- ── TRIGGER ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.profiles (id, nome, role)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'nome', split_part(new.email,'@',1)),
    COALESCE(new.raw_user_meta_data->>'role', 'comercial')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
