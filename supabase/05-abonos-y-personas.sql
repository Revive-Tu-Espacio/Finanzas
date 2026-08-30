-- ============================================================
-- 05-abonos-y-personas.sql
-- Fecha: 29 de agosto de 2026
--
-- Por qué existe: la app registra desde hoy tres cosas que la
-- nube no conocía y por lo tanto tiraba en silencio al respaldar:
--
--   deudas.abonado                (lo ya pagado de una deuda)
--   cuentas_por_cobrar.persona    (quién te debe)
--   cuentas_por_cobrar.fecha_promesa (para cuándo quedó de pagar)
--   cuentas_por_cobrar.abonado    (lo que ya te ha pagado)
--
-- Sin esto, un cambio de dispositivo restaura los préstamos sin
-- nombre, sin fecha y como si nadie hubiera abonado nada.
--
-- Es seguro correrlo más de una vez (IF NOT EXISTS / OR REPLACE)
-- y es retrocompatible: los respaldos viejos no traen estos
-- campos y entran como cero o nulo, sin romper nada.
--
-- Se corre UNA vez en el SQL Editor de Supabase, completo.
-- ============================================================

-- ---------- 1. Columnas nuevas ----------

alter table public.deudas
  add column if not exists abonado numeric not null default 0
    check (abonado >= 0);

alter table public.cuentas_por_cobrar
  add column if not exists persona text
    check (persona is null or char_length(persona) <= 80);

alter table public.cuentas_por_cobrar
  add column if not exists fecha_promesa date;

alter table public.cuentas_por_cobrar
  add column if not exists abonado numeric not null default 0
    check (abonado >= 0);

-- ---------- 2. Exportar: bajar el respaldo con los campos nuevos ----------
-- Cambios respecto a la versión anterior, todos aditivos:
--   · deudas:    + 'abonado'
--   · porCobrar: + 'persona', 'fechaPromesa', 'abonado'
--   · porCobrar: + 'creado' (epoch ms desde creado_en, como ya lo
--     hacía movimientos) para que el orden de la lista sobreviva
--     una restauración.

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

-- ---------- 3. Importar: subir el respaldo con los campos nuevos ----------
-- Cambios respecto a la versión anterior:
--   · deudas:             abonado con coalesce(..., 0)
--   · cuentas_por_cobrar: persona, fecha_promesa y abonado
-- Todo lo demás queda idéntico, incluido el contrato de conteos
-- que devuelve y la validación de sesión.

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

  -- Deudas (ahora con lo ya abonado)
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

  -- Cuentas por cobrar (ahora con persona, fecha prometida y abonos)
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

-- ---------- 4. Verificación (solo lectura, corre al final) ----------
-- Debe regresar las 4 columnas nuevas:

select table_name, column_name, data_type
from information_schema.columns
where table_schema = 'public'
  and ((table_name = 'deudas' and column_name = 'abonado')
    or (table_name = 'cuentas_por_cobrar'
        and column_name in ('persona', 'fecha_promesa', 'abonado')))
order by table_name, column_name;
