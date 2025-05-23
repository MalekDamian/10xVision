-- migration: create full initial schema
-- purpose: define all core tables, partitions, indexes, and row level security policies
-- affected tables: cameras, alerts (partitioned), detections (partitioned), known_faces, known_plates, users, login_attempts
-- special considerations: use pgvector extension, enable rls on all tables, partition alerts and detections by date, set up daily partitions, and retention via external service

-- enable required extensions
create extension if not exists vector;

-- as a superuser in psql
create role anon nologin;
create role authenticated nologin;

-- =====================================
-- 1. cameras table
-- =====================================
create table if not exists public.cameras (
    id uuid primary key,
    name text not null unique,
    location text,
    created_at timestamptz not null default now()
);

-- enable row level security
alter table public.cameras enable row level security;

-- rls policies for cameras
-- allow anyone (anon and authenticated) to select camera metadata
create policy cameras_select_anon on public.cameras
    for select to anon
    using (true);
create policy cameras_select_auth on public.cameras
    for select to authenticated
    using (true);

-- allow only authenticated users to insert, update, delete camera records
create policy cameras_insert_auth on public.cameras
    for insert to authenticated
    with check (true);
create policy cameras_update_auth on public.cameras
    for update to authenticated
    using (true)
    with check (true);
create policy cameras_delete_auth on public.cameras
    for delete to authenticated
    using (true);

-- =====================================
-- 2. alerts table (partitioned by range on event_time)
-- =====================================
ccreate table if not exists public.alerts (
  event_time    timestamptz not null,
  id            uuid         not null,
  camera_id     uuid         not null references public.cameras(id) on delete cascade,
  type          text         not null check (type in ('face','plate')),
  label         text         not null default 'unknown',
  thumbnail_path text        not null,
  created_at    timestamptz  not null default now(),

  primary key (event_time, id)  -- must include partition column
)
partition by range (event_time);

-- recreate today’s partition as an example:
create table if not exists public.alerts_20250523
  partition of public.alerts
  for values from ('2025-05-23 00:00:00+00') to ('2025-05-24 00:00:00+00');

create index if not exists idx_alerts_event_time on public.alerts(event_time);
create index if not exists idx_alerts_label      on public.alerts(label);

-- enable row level security on parent and partitions
alter table public.alerts enable row level security;
alter table public.alerts_20250523 enable row level security;

-- rls policies for alerts
-- allow select to authenticated only
create policy alerts_select_auth on public.alerts
    for select to authenticated
    using (true);
-- no insert/update/delete via API (managed by services)

-- =====================================
-- 3. detections table (partitioned by range on detected_at)
-- =====================================
create table public.detections (
  detected_at      timestamptz    not null,
  id               uuid           not null,
  alert_event_time timestamptz    not null,  -- must supply the alert’s event_time
  alert_id         uuid           not null,
  object_type      text           not null check (object_type in ('face','plate','person','vehicle')),
  confidence       double precision not null,
  created_at       timestamptz    not null default now(),

  primary key (detected_at, id),

  -- composite FK referencing the parent’s composite PK
  foreign key (alert_event_time, alert_id)
    references public.alerts(event_time, id)
    on delete cascade
)
partition by range (detected_at);

-- then your daily partition:
create table public.detections_20250523
  partition of public.detections
  for values from ('2025-05-23 00:00:00+00') to ('2025-05-24 00:00:00+00');

-- indexes
create index idx_detections_alert_id      on public.detections(alert_id);
create index idx_detections_detected_at   on public.detections(detected_at);

-- enable row level security
alter table public.detections enable row level security;
alter table public.detections_20250523 enable row level security;

-- rls policies for detections
-- allow select to authenticated only
create policy detections_select_auth on public.detections
    for select to authenticated
    using (true);

-- =====================================
-- 4. known_faces table
-- =====================================
create table if not exists public.known_faces (
    id uuid primary key,
    name text not null unique,
    embedding vector not null,
    added_at timestamptz not null default now()
);

-- index on name
create index if not exists idx_known_faces_name on public.known_faces(name);

-- enable row level security
alter table public.known_faces enable row level security;

-- rls policies for known_faces
-- authenticated users can select known faces
create policy known_faces_select_auth on public.known_faces
    for select to authenticated
    using (true);
-- no insert/update/delete via API

-- =====================================
-- 5. known_plates table
-- =====================================
create table if not exists public.known_plates (
    id uuid primary key,
    plate_number text not null unique,
    embedding vector not null,
    added_at timestamptz not null default now()
);

-- index on plate_number
create index if not exists idx_known_plates_number on public.known_plates(plate_number);

-- enable row level security
alter table public.known_plates enable row level security;

-- rls policies for known_plates
-- authenticated users can select known plates
create policy known_plates_select_auth on public.known_plates
    for select to authenticated
    using (true);

-- =====================================
-- 6. users table
-- =====================================
create table if not exists public.users (
    id uuid primary key,
    username text not null unique,
    password_hash text not null,
    created_at timestamptz not null default now()
);

-- enable row level security
alter table public.users enable row level security;


create schema if not exists auth;

create or replace function auth.uid()
  returns uuid
  language sql
  immutable
as $$
  select null::uuid;
$$;

-- rls policies for users
-- allow user to select their own record
create policy users_select_self on public.users
    for select to authenticated
    using (auth.uid() = id);
-- allow users to insert their own record
create policy users_insert on public.users
    for insert to authenticated
    with check (auth.uid() = id);

-- =====================================
-- 7. login_attempts table
-- =====================================
create table if not exists public.login_attempts (
    id uuid primary key,
    user_id uuid not null references public.users(id) on delete cascade,
    attempt_time timestamptz not null default now(),
    success boolean not null,
    ip_address inet
);

-- index on user_id and attempt_time
create index if not exists idx_login_attempts_user_time on public.login_attempts(user_id, attempt_time);

-- enable row level security
alter table public.login_attempts enable row level security;

-- rls policies for login_attempts
-- users can select their own login attempts
create policy login_attempts_select_self on public.login_attempts
    for select to authenticated
    using (auth.uid() = user_id);

-- =====================================
-- Note: partition maintenance and retention policies (drop old partitions) are handled by an external service job
-- transaction isolation levels to be set at session level: writes=serializable, reads=read committed
