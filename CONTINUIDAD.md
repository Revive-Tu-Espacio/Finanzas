# Escritura Segura — Documento de Continuidad y Cierre

**Notaría Pública DOS — Zapopan, Jalisco**
Plataforma de control de escrituras y expediente único de identificación (LFPIORPI Art. 17 fr. XII)

- **Fecha del documento:** 14 de junio de 2026
- **Estado:** EN PRODUCCIÓN — funcional

---

## 1. Resumen del proyecto

Escritura Segura es una plataforma web para que la Notaría Pública DOS de Zapopan controle el registro de sus escrituras y, cuando aplique, integre el expediente único de identificación (KYC) exigido por la actividad vulnerable de fe pública (Art. 17 fracción XII de la LFPIORPI).

La plataforma tiene dos paneles dentro de una sola aplicación: uno para colaboradores (captura de escrituras y expedientes) y uno para administrador (gestión de usuarios, auditoría y bitácora). Cada usuario entra con su correo y contraseña, y todo lo que captura queda registrado a su nombre.

Al 14 de junio de 2026, la plataforma está desplegada en producción, funcionando, con el histórico de escrituras ya importado.

---

## 2. Accesos y direcciones clave

| Recurso | Ubicación / URL |
|---|---|
| Aplicación en producción | https://aml-notaria-02-de-zapopan.vercel.app |
| Repositorio de código (GitHub) | github.com/Notaria-02-AML-CCFT/AML-Notaria-02-de-Zapopan |
| Organización GitHub | Notaria-02-AML-CCFT |
| Hosting / Deploy | Vercel (proyecto: aml-notaria-02-de-zapopan) |
| Base de datos, Auth y Storage | Supabase |
| Carpeta local del proyecto | `C:\Users\arman\escritura-segura` |
| Usuario administrador | asar@not2zapopan.com |

> **Nota de seguridad:** las llaves de Supabase fueron rotadas durante el desarrollo (las anteriores quedaron expuestas brevemente y ya no son válidas). Las llaves vigentes viven solo en el archivo `.env.local` local y en las variables de entorno de Vercel. **Nunca deben subirse a GitHub.**

---

## 3. Stack tecnológico

| Componente | Tecnología |
|---|---|
| Framework | Next.js 15.5.x (App Router) — versión con parche de seguridad |
| Lenguaje | TypeScript |
| Estilos | Tailwind CSS + componentes tipo shadcn/ui |
| Base de datos | Supabase (PostgreSQL) |
| Autenticación | Supabase Auth (correo + contraseña) |
| Almacenamiento de documentos | Supabase Storage (bucket privado `expedientes`) |
| Seguridad de datos | Row Level Security (RLS) por usuario |
| Despliegue | Vercel (deploy automático al hacer `git push`) |

---

## 4. Lo que ya está hecho

- Diseño migrado a Next.js con identidad visual de la notaría (paleta navy, logo integrado en portada, login y barra lateral).
- Autenticación real: cada usuario entra con correo y contraseña.
- Dos paneles: **Colaborador** (Resumen, Escrituras, Nueva escritura, Alertas) y **Administrador** (Resumen, Escrituras, Usuarios, Auditoría, Bitácora).
- Roles colaborador y admin, con protección de rutas: un colaborador no puede entrar al panel admin.
- Alta de usuarios desde el panel de administrador.
- Formulario de alta de escritura con lógica automática de actividad vulnerable (clasifica el acto por inciso a–e y determina si requiere Aviso según el umbral de UMA).
- Sección KYC para persona física y moral, con marcado de PEP y carga de documentos (interfaz lista).
- Importación del histórico: **2,342 escrituras** del Excel cargadas (rango: 9-ene-2023 al 13-jun-2026; números 11123 a 13464).
- Accountability: columna "Capturado por" (nombre real para capturas nuevas; nombre + " · histórico" para lo importado) y fecha/hora de carga. Bitácora de sesiones y acciones.
- Ordenamiento por número de escritura progresivo (columna numérica dedicada en la base de datos).
- Búsqueda simple (por número, acto, abogado, capturado por, cliente) y panel lateral de filtros avanzados (tipo de acto, vulnerable, estatus, abogado, rango de fechas y rango de número) en ambos paneles.
- Visibilidad compartida (Opción A): todos los colaboradores ven todas las escrituras.

---

## 5. Pendientes y próximos pasos

### 5.1 Pendiente inmediato (en curso al cerrar la sesión)

1. **Aplicar el último ajuste del filtro de fechas:** reemplazar el archivo `src/components/tabla-escrituras.tsx` (paquete `fix-fechas`) y hacer `git push`. Corregía que el filtro de fechas dejaba el listado en cero al excluir escrituras sin fecha registrada.
2. **Verificar** que el panel de colaborador muestre las escrituras ordenadas y que los filtros funcionen tras el deploy (recargar con Ctrl+F5).

### 5.2 Pendientes de mayor alcance

- **Carga real de documentos a Supabase Storage:** la interfaz para subir archivos del expediente KYC está lista, pero conviene afinar el guardado efectivo al bucket y la previsualización con URLs firmadas.
- **Validación de cumplimiento:** el área de cumplimiento de la notaría debe revisar la tabla de clasificación de actos vulnerables antes de apoyarse en ella para los Avisos oficiales, ya que el histórico se clasificó con reglas automáticas.
- **Valor de la UMA:** está parametrizado en `src/lib/utils.ts` (`UMA_DIARIA`). Debe actualizarse cada año.
- **Alertas y alarmas recurrentes:** definir y activar recordatorios automáticos cuando falte documentación o datos.
- **Si se vuelve a importar un Excel actualizado:** el script actual **AGREGA** registros (no reemplaza). Reimportar el mismo archivo duplicaría todo. Solicitar ajuste del script para insertar solo las escrituras que falten por número.

---

## 6. Cómo retomar el trabajo

### 6.1 Para editar y subir cambios

1. Abrir PowerShell en `C:\Users\arman\escritura-segura`
2. Confirmar que existe el archivo `.env.local` con las 3 llaves de Supabase (`NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`).
3. Para probar en local: `npm install` (la primera vez) y luego `npm run dev`
4. Tras hacer cambios: `npm run build` (verificar que compila), luego `git add .` / `git commit -m "mensaje"` / `git push`
5. Vercel redespliega automáticamente al recibir el push.

### 6.2 Flujo de Git cuando el push es rechazado

Si al hacer `git push` aparece "rejected (fetch first)", significa que GitHub tiene cambios que el equipo local no. Solución:

```bash
git pull origin main
# resolver conflictos si los hay:
git checkout --ours <archivo>   # para quedarse con la versión local
git add .
git commit -m "Resolver conflictos"
git push
```

### 6.3 Cambios en la base de datos

Los cambios de estructura o seguridad se hacen en Supabase → SQL Editor. Los scripts SQL del proyecto están en la carpeta `supabase/migrations/`. El mensaje "Success. No rows returned" es normal y significa que el comando se ejecutó bien.

---

## 7. Estructura del proyecto

| Carpeta / archivo | Contenido |
|---|---|
| `src/app/page.tsx` | Portada |
| `src/app/login/` | Inicio de sesión |
| `src/app/colaborador/` | Panel colaborador (resumen, escrituras, nueva, alertas) |
| `src/app/admin/` | Panel admin (resumen, escrituras, usuarios, auditoría, bitácora) |
| `src/components/` | Componentes: barra lateral, tabla con filtros, etc. |
| `src/lib/supabase/` | Conexión a Supabase (cliente, servidor, middleware, admin) |
| `src/middleware.ts` | Protección de rutas y verificación de rol |
| `supabase/migrations/` | Scripts SQL (estructura, seguridad, columnas) |
| `scripts/import-escrituras.ts` | Importación del histórico del Excel |
| `public/logo-notaria.png` | Logo de la notaría |

---

## 8. Reglas de actividad vulnerable implementadas

Conforme al Art. 17 fr. XII de la LFPIORPI:

| Inciso | Acto | ¿Requiere Aviso? |
|---|---|---|
| a | Compraventa, donación, permuta de inmuebles | Si ≥ 8,000 UMA |
| b | Poder irrevocable | Siempre |
| c | Constitución/modificación de personas morales; compraventa de acciones | Siempre |
| d | Fideicomisos traslativos o de garantía | Si ≥ 4,000 UMA |
| e | Mutuo o crédito fuera del sistema financiero | Siempre |

---

## 9. Notas de cierre

La plataforma quedó funcional y en producción. El trabajo de esta sesión cubrió: construcción completa, despliegue, integración del logo, configuración de roles y accountability, importación del histórico, ordenamiento y filtros de búsqueda.

El único cambio que quedó listo pero pendiente de subir al cerrar es la corrección del filtro de fechas (paquete `fix-fechas`). Al retomar, ese es el primer paso.

*Fin del documento de continuidad.*
