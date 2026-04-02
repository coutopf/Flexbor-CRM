# Flexbor CRM

Static CRM frontend backed by Supabase. The current project has two role-specific apps:

- `index.html`: landing page
- `comercial.html`: sales workflow for visits, opportunities, tasks, and contacts
- `gestor.html`: manager dashboard, team analytics, client management, and user creation
- `schema.sql`: Supabase database schema, grants, RLS policies, and realtime publication setup

## Current architecture

- Frontend: plain HTML, CSS, and browser-side JavaScript
- Backend: Supabase Auth, Postgres, and Realtime
- Hosting: any static host works well, including GitHub Pages, Netlify, Vercel, or Supabase Storage

## Supabase setup

1. Create a new Supabase project.
2. Open the SQL editor and run `schema.sql`.
3. Create your first manager user in Supabase Auth.
4. Make sure that first user has metadata `nome` and `role=gestor`, or update the generated `profiles` row after signup.
5. Replace the `SB_URL` and `SB_KEY` constants in `comercial.html` and `gestor.html` with your own project values.
6. Open `index.html` in a browser and test both roles.

## What the schema now covers

- `profiles` linked to `auth.users`
- `clientes`
- `contactos`
- `visitas`, including `contacto_id`
- `oportunidades`
- `tarefas`
- automatic profile creation on signup
- role-aware RLS for `comercial` and `gestor`
- indexes for the main CRM queries
- realtime publication for manager live refresh

## GitHub workflow

1. Create a GitHub repository for this folder.
2. Commit the current files.
3. Deploy the static files with your preferred host.
4. Keep Supabase project URL and anon key aligned with the deployed environment.

## Suggested next build steps

1. Move Supabase config out of the HTML files into a shared config file.
2. Add product catalog and quote/proposal records.
3. Add file attachments for visits and opportunities.
4. Add audit history and notes timeline per client.
5. Split the large inline scripts into shared modules for easier maintenance.
