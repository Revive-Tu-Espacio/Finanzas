-- ============================================================
-- 01-esquema-reconstruido.sql
-- Reconstruido desde la base VIVA el 29 de agosto de 2026.
--
-- Sustituye a los perdidos 01-esquema.sql y 02-bloques.sql, y
-- captura además lo que crearon 03 y 04 en su estado ACTUAL
-- (ya incluye los cambios de 05-abonos-y-personas.sql y
-- 06-vista-pendiente-con-abonos.sql).
--
-- USO: recuperación ante desastre. Correr COMPLETO en un
-- proyecto de Supabase EN BLANCO recrea todo el backend.
-- NO correrlo sobre el proyecto vivo: fallaría en los CREATE
-- de tablas y tipos que ya existen (a propósito — es la señal
-- de que te equivocaste de proyecto).
--
-- Fuente: consultas de solo lectura sobre information_schema,
-- pg_constraint, pg_indexes, pg_policies, pg_views, pg_proc,
-- pg_enum y pg_trigger, del 29 de agosto de 2026. Las
-- definiciones de funciones y vistas son verbatim. Lo poco
-- que no se pudo leer está marcado "NO VERIFICADO" al final.
-- ============================================================


-- ---------- 1. Tipos ----------

create type ambito_t          as enum ('personal', 'negocio');
create type ciclo_financiero  as enum ('diario', 'semanal', 'quincenal', 'mensual');
create type estrategia_deuda  as enum ('nieve', 'avalancha');
create type tipo_movimiento   as enum ('ingreso', 'gasto');


-- ---------- 2. Tablas ----------
-- Nota: la nulabilidad exacta no se capturó en las consultas;
-- los NOT NULL de abajo son los coherentes con los checks y las
-- funciones. Verificable con:
--   select table_name, column_name, is_nullable
--   from information_schema.columns where table_schema='public';

create table public.perfiles (
  id               uuid primary key references auth.users(id) on delete cascade,
  nombre           text not null
                     check (char_length(nombre) >= 1 and char_length(nombre) <= 40),
  ciclo            ciclo_financiero not null default 'quincenal',
  ancla            date not null default current_date,
  ingreso_estimado numeric not null default 0 check (ingreso_estimado >= 0),
  estrategia_deuda estrategia_deuda not null default 'nieve',
  usa_ambitos      boolean not null default false,
  ambito_activo    text not null default 'todo'
                     check (ambito_activo in ('todo', 'personal', 'negocio')),
  vista_periodo    text not null default 'ciclo'
                     check (vista_periodo in ('ciclo', 'mes')),
  ultimo_respaldo  timestamptz,
  creado_en        timestamptz not null default now(),
  actualizado_en   timestamptz not null default now()
);

create table public.importaciones (
  id         uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references auth.users(id) on delete cascade,
  archivo    text,
  destino    text check (destino in ('ingreso', 'gasto', 'cobrar')),
  periodo    text,
  registros  integer not null default 0,
  creado_en  timestamptz not null default now()
);

create table public.movimientos (
  id             uuid primary key default gen_random_uuid(),
  usuario_id     uuid not null references auth.users(id) on delete cascade,
  id_local       text not null,
  tipo           tipo_movimiento not null,
  monto          numeric not null check (monto > 0),
  categoria      text not null check (char_length(categoria) <= 40),
  ambito         ambito_t not null default 'personal',
  fecha          date not null,
  metodo         text check (char_length(metodo) <= 30),
  nota           text check (char_length(nota) <= 200),
  clasificado    boolean not null default false,
  importacion_id uuid references public.importaciones(id) on delete set null,
  creado_en      timestamptz not null default now(),
  unique (usuario_id, id_local)
);

create table public.bolsas (
  usuario_id uuid not null references auth.users(id) on delete cascade,
  categoria  text not null check (char_length(categoria) <= 40),
  tope       numeric not null check (tope > 0),
  primary key (usuario_id, categoria)
);

create table public.metas (
  id         uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references auth.users(id) on delete cascade,
  id_local   text not null,
  nombre     text not null
               check (char_length(nombre) >= 1 and char_length(nombre) <= 60),
  objetivo   numeric not null check (objetivo > 0),
  ahorrado   numeric not null default 0 check (ahorrado >= 0),
  fecha_meta date,
  creado_en  timestamptz not null default now(),
  unique (usuario_id, id_local)
);

create table public.deudas (
  id           uuid primary key default gen_random_uuid(),
  usuario_id   uuid not null references auth.users(id) on delete cascade,
  id_local     text not null,
  nombre       text not null
                 check (char_length(nombre) >= 1 and char_length(nombre) <= 60),
  saldo        numeric not null check (saldo >= 0),
  pago_mensual numeric not null default 0 check (pago_mensual >= 0),
  tasa         numeric not null default 0 check (tasa >= 0 and tasa <= 200),
  abonado      numeric not null default 0 check (abonado >= 0),
  creado_en    timestamptz not null default now(),
  unique (usuario_id, id_local)
);

create table public.cuentas_por_cobrar (
  id            uuid primary key default gen_random_uuid(),
  usuario_id    uuid not null references auth.users(id) on delete cascade,
  id_local      text not null,
  concepto      text not null
                  check (char_length(concepto) >= 1 and char_length(concepto) <= 120),
  monto         numeric not null check (monto > 0),
  tipo          text check (char_length(tipo) <= 40),
  ambito        ambito_t not null default 'personal',
  fecha         date,
  cobrado       boolean not null default false,
  fecha_cobro   date,
  movimiento_id uuid references public.movimientos(id) on delete set null,
  persona       text check (persona is null or char_length(persona) <= 80),
  fecha_promesa date,
  abonado       numeric not null default 0 check (abonado >= 0),
  creado_en     timestamptz not null default now(),
  unique (usuario_id, id_local),
  check ((not cobrado) or (fecha_cobro is not null))
);


-- ---------- 3. Índices ----------

create index idx_mov_usuario_fecha on public.movimientos using btree (usuario_id, fecha desc);
create index idx_mov_categoria     on public.movimientos using btree (usuario_id, categoria);
create index idx_mov_importacion   on public.movimientos using btree (importacion_id);
create index idx_mov_nota          on public.movimientos
  using gin (to_tsvector('spanish'::regconfig, coalesce(nota, ''::text)));
create index idx_metas_usuario     on public.metas using btree (usuario_id);
create index idx_deudas_usuario    on public.deudas using btree (usuario_id);
create index idx_cobrar_usuario    on public.cuentas_por_cobrar using btree (usuario_id, cobrado);
create index idx_import_usuario    on public.importaciones using btree (usuario_id, creado_en desc);


-- ---------- 4. RLS: cada quien lo suyo ----------
-- Estas siete políticas SON la seguridad de la nube. Un usuario
-- autenticado solo ve y toca filas con su propio auth.uid().

alter table public.perfiles           enable row level security;
alter table public.movimientos        enable row level security;
alter table public.bolsas             enable row level security;
alter table public.metas              enable row level security;
alter table public.deudas             enable row level security;
alter table public.cuentas_por_cobrar enable row level security;
alter table public.importaciones      enable row level security;

create policy perfil_propio on public.perfiles
  for all using (auth.uid() = id) with check (auth.uid() = id);
create policy movimientos_propios on public.movimientos
  for all using (auth.uid() = usuario_id) with check (auth.uid() = usuario_id);
create policy bolsas_propios on public.bolsas
  for all using (auth.uid() = usuario_id) with check (auth.uid() = usuario_id);
create policy metas_propios on public.metas
  for all using (auth.uid() = usuario_id) with check (auth.uid() = usuario_id);
create policy deudas_propios on public.deudas
  for all using (auth.uid() = usuario_id) with check (auth.uid() = usuario_id);
create policy cuentas_por_cobrar_propios on public.cuentas_por_cobrar
  for all using (auth.uid() = usuario_id) with check (auth.uid() = usuario_id);
create policy importaciones_propios on public.importaciones
  for all using (auth.uid() = usuario_id) with check (auth.uid() = usuario_id);


-- ---------- 5. Vistas (security_invoker: la RLS de la tabla aplica) ----------

create view public.v_resumen_mensual
with (security_invoker = true) as
select usuario_id,
       date_trunc('month'::text, fecha::timestamp with time zone)::date as mes,
       ambito,
       sum(monto) filter (where tipo = 'ingreso'::tipo_movimiento) as ingresos,
       sum(monto) filter (where tipo = 'gasto'::tipo_movimiento) as gastos,
       coalesce(sum(monto) filter (where tipo = 'ingreso'::tipo_movimiento), 0::numeric)
         - coalesce(sum(monto) filter (where tipo = 'gasto'::tipo_movimiento), 0::numeric) as saldo,
       count(*) as movimientos
  from movimientos
 group by usuario_id, date_trunc('month'::text, fecha::timestamp with time zone), ambito;

create view public.v_gasto_por_categoria
with (security_invoker = true) as
select usuario_id,
       date_trunc('month'::text, fecha::timestamp with time zone)::date as mes,
       ambito,
       categoria,
       sum(monto) as total,
       count(*) as movimientos
  from movimientos
 where tipo = 'gasto'::tipo_movimiento
 group by usuario_id, date_trunc('month'::text, fecha::timestamp with time zone), ambito, categoria;

create view public.v_por_cobrar_abierto
with (security_invoker = true) as
select usuario_id,
       ambito,
       coalesce(tipo, 'Sin clasificar'::text) as tipo,
       sum(greatest(monto - abonado, 0::numeric)) as pendiente,
       count(*) as cuentas
  from cuentas_por_cobrar
 where not cobrado
 group by usuario_id, ambito, coalesce(tipo, 'Sin clasificar'::text);


-- ---------- 6. Funciones de mantenimiento y topes ----------

create or replace function public.tocar_actualizado_en()
returns trigger
language plpgsql
as $function$
begin
  new.actualizado_en = now();
  return new;
end $function$;

create or replace function public.crear_perfil_al_registrarse()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  insert into public.perfiles (id, nombre, ancla)
  values (new.id,
          coalesce(nullif(new.raw_user_meta_data->>'nombre',''), 'Sin nombre'),
          current_date)
  on conflict (id) do nothing;
  return new;
end $function$;

create or replace function public.tope_por_usuario()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  n bigint;
  limite constant bigint := 50000;
begin
  execute format('select count(*) from %I where usuario_id = $1', tg_table_name)
    into n
    using new.usuario_id;

  if n >= limite then
    raise exception
      'Se alcanzó el máximo de % registros en %.', limite, tg_table_name
      using errcode = 'check_violation';
  end if;

  return new;
end;
$function$;


-- ---------- 7. Disparadores ----------

create trigger trg_perfiles_actualizado
  before update on public.perfiles
  for each row execute function public.tocar_actualizado_en();

create trigger tope_movimientos
  before insert on public.movimientos
  for each row execute function public.tope_por_usuario();

create trigger tope_cuentas_por_cobrar
  before insert on public.cuentas_por_cobrar
  for each row execute function public.tope_por_usuario();

-- El disparador que crea el perfil al registrarse vive en auth.users.
-- La función es verbatim; el NOMBRE del trigger no se pudo leer
-- (information_schema no muestra el esquema auth), así que este es
-- reconstruido con la convención usual:
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.crear_perfil_al_registrarse();


-- ---------- 8. Respaldo: exportar e importar (verbatim, versión 05) ----------

create or replace function public.exportar_respaldo()
returns jsonb
language sql
set search_path to 'public'
as $function$
  select jsonb_build_object(
    'version', 1,
    'perfil', (
      select jsonb_build_object(
        'nombre', nombre, 'ciclo', ciclo::text, 'ancla', ancla::text,
        'ingresoEstimado', ingreso_estimado, 'usaAmbitos', usa_ambitos,
        'ambitoActivo', ambito_activo, 'vistaPeriodo', vista_periodo)
      from perfiles where id = auth.uid()),
    'estrategiaDeuda', coalesce((select estrategia_deuda::text from perfiles where id = auth.uid()), 'nieve'),
    'movimientos', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', id_local, 'tipo', tipo::text, 'monto', monto, 'categoria', categoria,
        'ambito', ambito::text, 'fecha', fecha::text, 'metodo', coalesce(metodo,''),
        'nota', coalesce(nota,''), 'clasificado', clasificado,
        'creado', extract(epoch from creado_en) * 1000) order by fecha)
      from movimientos where usuario_id = auth.uid()), '[]'::jsonb),
    'presupuesto', coalesce((
      select jsonb_object_agg(categoria, tope)
      from bolsas where usuario_id = auth.uid()), '{}'::jsonb),
    'metas', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', id_local, 'nombre', nombre, 'objetivo', objetivo,
        'ahorrado', ahorrado, 'fechaMeta', fecha_meta))
      from metas where usuario_id = auth.uid()), '[]'::jsonb),
    'deudas', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', id_local, 'nombre', nombre, 'saldo', saldo,
        'pagoMensual', pago_mensual, 'tasa', tasa, 'abonado', abonado))
      from deudas where usuario_id = auth.uid()), '[]'::jsonb),
    'porCobrar', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', id_local, 'concepto', concepto, 'monto', monto, 'tipo', coalesce(tipo,''),
        'ambito', ambito::text, 'fecha', fecha, 'cobrado', cobrado, 'fechaCobro', fecha_cobro,
        'persona', persona, 'fechaPromesa', fecha_promesa, 'abonado', abonado,
        'creado', extract(epoch from creado_en) * 1000))
      from cuentas_por_cobrar where usuario_id = auth.uid()), '[]'::jsonb)
  );
$function$;

create or replace function public.importar_respaldo(p jsonb)
returns jsonb
language plpgsql
set search_path to 'public'
as $function$
declare
  u uuid := auth.uid();
  n_mov int := 0; n_bol int := 0; n_met int := 0; n_deu int := 0; n_cob int := 0;
begin
  if u is null then
    raise exception 'No hay sesión iniciada: ejecuta esto autenticado, no con la llave de servicio';
  end if;

  -- Perfil
  if p ? 'perfil' and p->'perfil' is not null and jsonb_typeof(p->'perfil') = 'object' then
    insert into perfiles (id, nombre, ciclo, ancla, ingreso_estimado, estrategia_deuda,
                          usa_ambitos, ambito_activo, vista_periodo)
    values (
      u,
      coalesce(nullif(p->'perfil'->>'nombre',''), 'Sin nombre'),
      coalesce((p->'perfil'->>'ciclo')::ciclo_financiero, 'quincenal'),
      coalesce((p->'perfil'->>'ancla')::date, current_date),
      coalesce((p->'perfil'->>'ingresoEstimado')::numeric, 0),
      coalesce((p->>'estrategiaDeuda')::estrategia_deuda, 'nieve'),
      coalesce((p->'perfil'->>'usaAmbitos')::boolean, false),
      coalesce(nullif(p->'perfil'->>'ambitoActivo',''), 'todo'),
      coalesce(nullif(p->'perfil'->>'vistaPeriodo',''), 'ciclo')
    )
    on conflict (id) do update set
      nombre = excluded.nombre, ciclo = excluded.ciclo, ancla = excluded.ancla,
      ingreso_estimado = excluded.ingreso_estimado, estrategia_deuda = excluded.estrategia_deuda,
      usa_ambitos = excluded.usa_ambitos, ambito_activo = excluded.ambito_activo,
      vista_periodo = excluded.vista_periodo;
  end if;

  -- Movimientos
  insert into movimientos (usuario_id, id_local, tipo, monto, categoria, ambito,
                           fecha, metodo, nota, clasificado)
  select u,
         m->>'id',
         (m->>'tipo')::tipo_movimiento,
         (m->>'monto')::numeric,
         coalesce(nullif(m->>'categoria',''), 'otros'),
         coalesce(nullif(m->>'ambito',''), 'personal')::ambito_t,
         (m->>'fecha')::date,
         nullif(m->>'metodo',''),
         nullif(m->>'nota',''),
         coalesce((m->>'clasificado')::boolean, false)
  from jsonb_array_elements(coalesce(p->'movimientos', '[]'::jsonb)) m
  where m->>'id' is not null and (m->>'monto')::numeric > 0
  on conflict (usuario_id, id_local) do update set
    tipo = excluded.tipo, monto = excluded.monto, categoria = excluded.categoria,
    ambito = excluded.ambito, fecha = excluded.fecha, metodo = excluded.metodo,
    nota = excluded.nota, clasificado = excluded.clasificado;
  get diagnostics n_mov = row_count;

  -- Bolsas: en el respaldo es un objeto { categoria: tope }
  insert into bolsas (usuario_id, categoria, tope)
  select u, clave, valor::numeric
  from jsonb_each_text(coalesce(p->'presupuesto', '{}'::jsonb)) as b(clave, valor)
  where valor::numeric > 0
  on conflict (usuario_id, categoria) do update set tope = excluded.tope;
  get diagnostics n_bol = row_count;

  -- Metas
  insert into metas (usuario_id, id_local, nombre, objetivo, ahorrado, fecha_meta)
  select u, g->>'id', g->>'nombre', (g->>'objetivo')::numeric,
         coalesce((g->>'ahorrado')::numeric, 0), nullif(g->>'fechaMeta','')::date
  from jsonb_array_elements(coalesce(p->'metas', '[]'::jsonb)) g
  where g->>'id' is not null
  on conflict (usuario_id, id_local) do update set
    nombre = excluded.nombre, objetivo = excluded.objetivo,
    ahorrado = excluded.ahorrado, fecha_meta = excluded.fecha_meta;
  get diagnostics n_met = row_count;

  -- Deudas (con lo ya abonado)
  insert into deudas (usuario_id, id_local, nombre, saldo, pago_mensual, tasa, abonado)
  select u, dd->>'id', dd->>'nombre', (dd->>'saldo')::numeric,
         coalesce((dd->>'pagoMensual')::numeric, 0), coalesce((dd->>'tasa')::numeric, 0),
         coalesce((dd->>'abonado')::numeric, 0)
  from jsonb_array_elements(coalesce(p->'deudas', '[]'::jsonb)) dd
  where dd->>'id' is not null
  on conflict (usuario_id, id_local) do update set
    nombre = excluded.nombre, saldo = excluded.saldo,
    pago_mensual = excluded.pago_mensual, tasa = excluded.tasa,
    abonado = excluded.abonado;
  get diagnostics n_deu = row_count;

  -- Cuentas por cobrar (con persona, fecha prometida y abonos)
  insert into cuentas_por_cobrar (usuario_id, id_local, concepto, monto, tipo,
                                  ambito, fecha, cobrado, fecha_cobro,
                                  persona, fecha_promesa, abonado)
  select u, c->>'id', c->>'concepto', (c->>'monto')::numeric, nullif(c->>'tipo',''),
         coalesce(nullif(c->>'ambito',''), 'personal')::ambito_t,
         nullif(c->>'fecha','')::date,
         coalesce((c->>'cobrado')::boolean, false),
         nullif(c->>'fechaCobro','')::date,
         nullif(c->>'persona',''),
         nullif(c->>'fechaPromesa','')::date,
         coalesce((c->>'abonado')::numeric, 0)
  from jsonb_array_elements(coalesce(p->'porCobrar', '[]'::jsonb)) c
  where c->>'id' is not null
  on conflict (usuario_id, id_local) do update set
    concepto = excluded.concepto, monto = excluded.monto, tipo = excluded.tipo,
    ambito = excluded.ambito, fecha = excluded.fecha,
    cobrado = excluded.cobrado, fecha_cobro = excluded.fecha_cobro,
    persona = excluded.persona, fecha_promesa = excluded.fecha_promesa,
    abonado = excluded.abonado;
  get diagnostics n_cob = row_count;

  return jsonb_build_object(
    'movimientos', n_mov, 'bolsas', n_bol, 'metas', n_met,
    'deudas', n_deu, 'por_cobrar', n_cob);
end $function$;

-- Envoltorios que llama la app (parámetros NOMBRADOS: p_datos, no p)

create or replace function public.exportar_respaldo_json()
returns jsonb
language sql
set search_path to 'public'
as $function$
  select exportar_respaldo();
$function$;

create or replace function public.importar_respaldo_json(p_datos jsonb)
returns jsonb
language sql
set search_path to 'public'
as $function$
  select importar_respaldo(p_datos);
$function$;


-- ---------- 9. NO VERIFICADO ----------
-- Dos cosas que la documentación menciona y estas consultas no
-- alcanzaron a leer. Si se reconstruye desde cero, verificarlas
-- en el proyecto vivo ANTES con estas consultas y copiar lo que
-- salga:
--
-- a) Timeouts de sentencia (probablemente a nivel de rol):
--    select r.rolname, s.setconfig
--    from pg_db_role_setting s join pg_roles r on r.oid = s.setrole;
--
-- b) Permisos/grants sobre tablas y funciones (por si el original
--    revocaba algo a anon):
--    select grantee, table_name, privilege_type
--    from information_schema.role_table_grants
--    where table_schema = 'public' and grantee in ('anon','authenticated');
