-- Run this after auth-tables.sql. Safe to run even if auth-tables.sql was
-- already executed with the older (authenticated-only) ip_projects policy.

-- 1. Make ip_projects publicly readable (title/genre/stage/logline are not
--    sensitive — only the full synopsis should require login).
drop policy if exists "Authenticated users can read ip_projects" on ip_projects;
drop policy if exists "Anyone can read ip_projects" on ip_projects;

create policy "Anyone can read ip_projects" on ip_projects
  for select using (true);

-- 2. Protected synopsis table — only logged-in users can read it.
create table if not exists ip_project_synopses (
  project_id text primary key references ip_projects(id) on delete cascade,
  synopsis text not null,
  updated_at timestamptz default now()
);

alter table ip_project_synopses enable row level security;

create policy "Authenticated users can read synopses" on ip_project_synopses
  for select using (auth.role() = 'authenticated');

create policy "Admins can insert synopses" on ip_project_synopses
  for insert with check (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

create policy "Admins can update synopses" on ip_project_synopses
  for update using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

create policy "Admins can delete synopses" on ip_project_synopses
  for delete using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );
