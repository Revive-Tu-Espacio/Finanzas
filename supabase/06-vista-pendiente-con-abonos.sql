-- ============================================================
-- 06-vista-pendiente-con-abonos.sql
-- Fecha: 29 de agosto de 2026
--
-- v_por_cobrar_abierto sumaba el monto original de cada cuenta.
-- Desde que existen los abonos (05-abonos-y-personas.sql), el
-- "pendiente" real es monto - abonado. Mismas columnas, mismo
-- orden, mismo nombre; solo cambia el cálculo.
--
-- security_invoker va explícito para conservar la protección
-- que ya tenían las tres vistas: la vista consulta con los
-- permisos de quien pregunta, y la RLS de la tabla aplica.
--
-- Seguro de correr más de una vez.
-- ============================================================

create or replace view public.v_por_cobrar_abierto
with (security_invoker = true) as
select usuario_id,
       ambito,
       coalesce(tipo, 'Sin clasificar'::text) as tipo,
       sum(greatest(monto - abonado, 0::numeric)) as pendiente,
       count(*) as cuentas
  from cuentas_por_cobrar
 where not cobrado
 group by usuario_id, ambito, coalesce(tipo, 'Sin clasificar'::text);

-- Verificación (solo lectura): pendiente ya descuenta abonos.
select * from v_por_cobrar_abierto;
