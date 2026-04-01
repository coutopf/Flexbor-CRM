-- 1. LIMPEZA (Para evitar o erro que tiveste)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 2. TABELAS
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  nome text NOT NULL,
  role text NOT NULL DEFAULT 'comercial',
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.clientes (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  nome text NOT NULL,
  nif text UNIQUE,
  email text,
  tel text,
  criado_por uuid REFERENCES public.profiles(id),
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.contactos (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  cliente_id uuid REFERENCES public.clientes(id) ON DELETE CASCADE,
  nome text NOT NULL,
  cargo text,
  tel text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.visitas (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  cliente_id uuid REFERENCES public.clientes(id) ON DELETE CASCADE,
  contacto_id uuid REFERENCES public.contactos(id) ON DELETE SET NULL,
  data_visita timestamptz DEFAULT now(),
  resumo text,
  criado_por uuid REFERENCES public.profiles(id),
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.oportunidades (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  cliente_id uuid REFERENCES public.clientes(id) ON DELETE CASCADE,
  nome text NOT NULL,
  valor decimal(12,2) DEFAULT 0,
  fase text DEFAULT 'Prospeção',
  criado_por uuid REFERENCES public.profiles(id),
  atualizado_em timestamptz DEFAULT now()
);

-- 3. FUNÇÃO E TRIGGER (Automatização do Perfil)
CREATE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, nome, role)
  VALUES (new.id, coalesce(new.raw_user_meta_data->>'nome', new.email), 'comercial');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 4. PERMISSÕES
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;