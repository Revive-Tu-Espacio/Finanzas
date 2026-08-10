-- ================================================================
-- 04-rpc.sql · Envolturas para llamar desde la app
--
-- La app llama las funciones por HTTP, y PostgREST exige que los
-- parámetros vengan por nombre. Estas envolturas fijan un nombre
-- conocido (p_datos) sin tocar las funciones originales.
--
-- Se corre UNA vez, sin declarar sesión de usuario.
-- ================================================================

create or replace function importar_respaldo_json(p_datos jsonb)
returns jsonb
language sql
security invoker
set search_path = public
as $$
  select importar_respaldo(p_datos);
$$;

comment on function importar_respaldo_json(jsonb) is
  'Envoltura de importar_respaldo con parámetro nombrado, para PostgREST. '
  'security invoker: corre con los permisos de quien llama, así la RLS aplica.';

create or replace function exportar_respaldo_json()
returns jsonb
language sql
security invoker
set search_path = public
as $$
  select exportar_respaldo();
$$;

comment on function exportar_respaldo_json() is
  'Envoltura de exportar_respaldo, para PostgREST.';

revoke all on function importar_respaldo_json(jsonb) from anon;
revoke all on function exportar_respaldo_json()     from anon;
grant execute on function importar_respaldo_json(jsonb) to authenticated;
grant execute on function exportar_respaldo_json()      to authenticated;

-- Verificación
select p.proname, pg_get_function_identity_arguments(p.oid) as argumentos
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.proname like '%respaldo%'
order by 1;
