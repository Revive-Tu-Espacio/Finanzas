-- ============================================================
-- 08-lint-search-path.sql
-- Fecha: 29 de agosto de 2026
--
-- El linter de Supabase marcó tocar_actualizado_en() sin
-- search_path fijo. Todas las demás funciones ya lo traen; a
-- esta se le había pasado. Endurece contra que alguien cuele
-- objetos de otro esquema. Sin cambios de comportamiento.
--
-- Seguro de correr más de una vez.
-- ============================================================

create or replace function public.tocar_actualizado_en()
returns trigger
language plpgsql
set search_path to 'public'
as $function$
begin
  new.actualizado_en = now();
  return new;
end $function$;

-- Verificación (solo lectura): debe mostrar el search_path en la config.
select proname, proconfig
from pg_proc
where proname = 'tocar_actualizado_en';
