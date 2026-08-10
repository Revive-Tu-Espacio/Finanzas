-- ================================================================
-- 03-limites.sql · Defensas de la base de datos
-- Proyecto: Revive tu espacio-Finanzas
--
-- Se corre UNA vez, en el SQL Editor, sin declarar sesión de usuario
-- (estas instrucciones son de administración, no de datos).
--
-- Complementa a la RLS, no la sustituye. La RLS decide QUIÉN ve QUÉ;
-- esto limita CUÁNTO puede pedir y CUÁNTO puede escribir.
-- ================================================================


-- ----------------------------------------------------------------
-- 1. Tiempo máximo por consulta
--
-- Sin esto, una consulta mal formada puede quedarse corriendo y
-- consumir la instancia. Cinco segundos es holgado: las consultas
-- de esta app tardan milisegundos.
-- ----------------------------------------------------------------

alter role authenticated set statement_timeout = '5s';
alter role anon          set statement_timeout = '3s';


-- ----------------------------------------------------------------
-- 2. Tope de filas por respuesta
--
-- Aunque la RLS ya filtra por usuario, esto evita que una sola
-- petición intente traerse el historial completo de golpe.
-- ----------------------------------------------------------------

alter role authenticated set pgrst.db_max_rows = '2000';
alter role anon          set pgrst.db_max_rows = '0';

notify pgrst, 'reload config';


-- ----------------------------------------------------------------
-- 3. Tope de registros por usuario
--
-- Defensa contra el llenado masivo: si alguien automatiza inserciones
-- con su propio token, la RLS no lo detiene porque los registros SON
-- suyos. Esto sí.
--
-- 50,000 movimientos son unos cien años de captura diaria. Quien lo
-- rebase no está usando la app: la está atacando.
-- ----------------------------------------------------------------

create or replace function tope_por_usuario()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
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
$$;

comment on function tope_por_usuario() is
  'Rechaza inserciones cuando el usuario ya alcanzó el tope de filas '
  'en la tabla. Se dispara por fila, solo en INSERT.';

create trigger tope_movimientos
  before insert on movimientos
  for each row execute function tope_por_usuario();

create trigger tope_cuentas_por_cobrar
  before insert on cuentas_por_cobrar
  for each row execute function tope_por_usuario();


-- ----------------------------------------------------------------
-- 4. Verificación
-- ----------------------------------------------------------------

select rolname, rolconfig
from pg_roles
where rolname in ('authenticated', 'anon');

select event_object_table as tabla, trigger_name
from information_schema.triggers
where trigger_name like 'tope_%'
order by 1;
