-- =========================================================
-- Marcia Bizi · Marmitas Fit — schema do banco
-- Rode este arquivo inteiro em: Supabase → SQL Editor → New query → Run
-- Pode rodar mais de uma vez sem quebrar nada.
-- =========================================================

-- ---------------------------------------------------------
-- 1) Tabela de dados
--    O app guarda tudo em duas linhas: 'pedidos' e 'custos'.
-- ---------------------------------------------------------
create table if not exists public.app_data (
  key        text primary key,
  value      jsonb not null,
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------
-- 2) Segurança (RLS)
--    Sem login = sem acesso. Nem leitura, nem escrita.
--    Só quem tem uma conta criada por você no painel do
--    Supabase (role 'authenticated') enxerga os dados.
-- ---------------------------------------------------------
alter table public.app_data enable row level security;

-- Remove a policy aberta da versão antiga do projeto, se existir.
drop policy if exists "permitir tudo (app interno sem login)" on public.app_data;

drop policy if exists "logados podem ler" on public.app_data;
create policy "logados podem ler"
  on public.app_data for select
  to authenticated
  using (true);

drop policy if exists "logados podem inserir" on public.app_data;
create policy "logados podem inserir"
  on public.app_data for insert
  to authenticated
  with check (true);

drop policy if exists "logados podem atualizar" on public.app_data;
create policy "logados podem atualizar"
  on public.app_data for update
  to authenticated
  using (true)
  with check (true);

-- Ninguém apaga linha: o app só sobrescreve os dois registros.
-- (a ausência de policy de DELETE já bloqueia)

-- ---------------------------------------------------------
-- 3) Sincronização em tempo real entre dispositivos
-- ---------------------------------------------------------
do $$
begin
  alter publication supabase_realtime add table public.app_data;
exception
  when duplicate_object then null;
end $$;
