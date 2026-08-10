# Continuidad — Finanzas Revive tu Espacio A.C.
### Cierre de sesión · 10 de agosto de 2026

Sustituye al documento del 9 de agosto. Sirve para retomar sin releer la conversación: estado real, decisiones con su razón, lo pendiente, y los errores que ya se pagaron una vez.

---

## 1. Qué es esto

Una aplicación de control de finanzas personales para las personas que acompaña Revive tu Espacio A.C. Un solo archivo HTML, sin servidor obligatorio, sin cuentas obligatorias, sin dependencias externas. Los datos viven en el navegador de cada persona.

**En producción:** repositorio `github.com/Revive-Tu-Espacio/Finanzas`, desplegado en Vercel.
**Versión vigente:** `index.html` de **267694 bytes**, commit `1aaa66a`.

Se usa además como herramienta personal de Armando, con ámbito de negocio activado.

**Novedad de esta sesión:** ya existe una nube opcional. La base de datos está montada, probada y cargada; la app entra con código por correo y sube o baja el respaldo a mano. No hay sincronización automática todavía.

---

## 2. Estado del código

### Funciones terminadas

| Módulo | Qué hace |
|---|---|
| Alta y perfil | Nombre, ciclo, fecha ancla, ingreso estimado |
| Captura | Ingreso o gasto en menos de 10 segundos; sugiere categoría desde la nota |
| Resumen | Balance con comparativo contra el periodo anterior, gasto por categoría, origen del ingreso, gráfica de flujo diario, cuentas por cobrar abiertas |
| Ventana de revisión | Selector "por ciclo" o "por mes", independiente del ciclo de cobro |
| Movimientos | Buscador en vivo, filtros por tipo y categoría, filtro por monto y fecha, dos presentaciones, paginado de 25 en 25, panel lateral para editar |
| Bolsas | Tope por categoría con semáforo al 80% y al 100% |
| Metas | Objetivo con fecha; calcula cuánto apartar por periodo |
| Deudas | Bola de nieve vs. avalancha, meses estimados, capacidad de endeudamiento |
| Cuentas por cobrar | Pestaña "Me deben"; al cobrarse genera el ingreso, y admite cobro parcial |
| Alertas | Campana con contador; nueve situaciones vigiladas |
| Importar | Asistente de 5 pasos para .xlsx y .csv, con mapeo de columnas y deduplicación |
| Reclasificar | Propone categoría por concepto para lo que quedó en "Otros" |
| Exportar | Estado financiero en Excel de 3 hojas, reporte en PDF, respaldo JSON, CSV simple |
| Ámbito | Separación personal / negocio, apagada por omisión |
| **Nube** | **Opcional. Acceso por código al correo, subida y bajada manual del respaldo** |

### Lo que se agregó el 10 de agosto

**Módulo `Nube`.** Llamadas REST directas a Supabase, sin la librería oficial. Autenticación por código de un solo uso; sin contraseñas. Contrato de errores uniforme: toda función pública devuelve `{ok:true, datos}` o `{ok:false, codigo, mensaje}`, nunca lanza. Códigos: `RED`, `LIMITE`, `CREDENCIAL`, `SESION`, `SERVIDOR`. Renueva el token solo y reintenta una vez ante un 401.

**Tarjeta "Guardar en la nube"** en Ajustes, arriba de "Personal y negocio". Apagada explica qué hace; encendida muestra el correo y tres acciones.

**Movimientos: paginado en vez de carga progresiva.** 25 por página, con `Anterior · 1–25 de 32 · Siguiente`. Al cambiar de página sube al inicio de la lista.

**Movimientos: dos presentaciones.** *Por día*, agrupado con neto diario. *Mayor a menor*, entradas y salidas en dos columnas, cada una de mayor a menor. Abajo de 760 px las columnas se apilan.

**Movimientos: filtro por monto y fecha,** en una hoja aparte, con validación y pastillas que muestran lo que está puesto y se quitan tocándolas.

**Resumen: cuatro bloques nuevos.** Comparativo con el periodo anterior; tarjeta "De dónde vino"; gráfica de flujo diario en SVG dibujado a mano; tarjeta "Te deben". Las barras de categoría se tocan y abren el panel lateral con los movimientos que las componen.

**Arranque a prueba de fallos.** Si el primer `pintar()` truena, ya no se queda a la vista la pantalla de rescate de WhatsApp con un mensaje falso: sale un aviso honesto y un botón para descargar el respaldo.

### Arquitectura, en corto

- **Vanilla JS**, sin framework ni build. Todo el estado en el objeto `datos`; se repinta con `pintar()`.
- **`Almacen`** sigue siendo el único punto que toca el almacenamiento local, y **no se modificó**. La nube es un módulo aparte que se invoca a mano. Reescribir `Almacen` es lo que viene cuando haya sincronización.
- **`Nube`** encapsula Supabase. Su contrato está pensado para que, al llegar la sincronización, `Almacen` lo llame sin que el resto del código se entere.
- **Generador y lector de .xlsx propios.** Un xlsx es un ZIP con XML; se arma con CRC32 y método "store", y se lee con `DecompressionStream('deflate-raw')`.
- **PDF** vía `window.print()` sobre un bloque oculto con `@media print`.
- **Gráficas en SVG en línea**, sin librería. Nada externo, nada que se rompa sin conexión.
- **Sin animaciones** salvo el panel lateral (220 ms, ease-out, respeta `prefers-reduced-motion`).

---

## 3. Decisiones que no conviene revertir sin pensarlo

**Local-first.** La app funciona completa sin cuenta. La nube es opcional y va del lado del premium, porque el corte del premium está en lo que cuesta operar —servidores, almacenamiento, historial largo— no en lo que la gente necesita para ordenar su dinero.

**El login no es un muro.** No hay pantalla de acceso al abrir. El interruptor en Ajustes dice "Guardar en la nube", no "iniciar sesión", y la autenticación aparece como consecuencia. Poner una puerta al inicio cambiaría el trato con quien más cuesta retener.

**Sin la librería de Supabase.** Cargarla desde un CDN obligaría a abrir `script-src` y rompería el funcionamiento sin conexión. Son llamadas REST directas.

**La llave anónima va incrustada en el HTML.** Es pública por diseño; lo que protege los datos es la RLS. La `service_role` no aparece en ninguna parte del repositorio.

**El ciclo de cobro y la ventana de revisión son cosas distintas.**

**El ámbito negocio está apagado por omisión.**

**El clasificador no adivina.** Un gasto mal clasificado es peor que uno sin clasificar: el primero se esconde en una gráfica que parece correcta.

**Las cuentas por cobrar no son ingresos.** Solo generan movimiento al cobrarse.

**El estado financiero no dice "conforme a las NIF".** La Nota 1 declara base de efectivo, sin auditar.

**Lenguaje sin jerga.** "Te queda", no "flujo neto". "Bolsas", no "partidas presupuestales".

**Agrupar por día y ordenar por monto son excluyentes.** Como opciones independientes producen listas con encabezados de fecha salteados. Por eso el control tiene dos presentaciones, no dos casillas.

**Los filtros de monto y fecha operan dentro del periodo abierto.** Ya existe navegación por periodo; si el filtro la ignorara, habría dos mecanismos peleándose por decidir qué se ve.

**En dos columnas, los totales del encabezado son de todo lo filtrado, no de la página.** Un total que cambia al pasar de hoja deja de ser un dato en el que confiar.

---

## 4. Errores que ya se pagaron

Vale la pena leerlos antes de tocar código: todos costaron una vuelta.

| Qué pasó | Causa | Cómo quedó |
|---|---|---|
| Pantalla en blanco en WhatsApp | El visor de documentos no ejecuta JavaScript | Pantalla de rescate estática |
| Se importaron ingresos como gastos | Dos columnas se llamaban "CANTIDAD" | Cada columna se muestra con su letra y ejemplos |
| Un gasto duplicado | La deduplicación comparaba "Café" y "Cafe" como distintos | La clave normaliza acentos y signos |
| Importación que "no aparecía" | Los movimientos cayeron en periodos anteriores al visible | Tras importar salta al periodo correcto |
| Segunda importación al destino equivocado | El asistente heredaba el destino de la anterior | Se reinicia al abrirlo |
| Fuga en las vistas de Supabase | Una vista corre con permisos de quien la creó y se salta la RLS | `security_invoker = true` en las tres vistas |
| **Se importó todo como "personal"** | **El asistente usa el ámbito activo y la separación estaba apagada** | **Encender la separación ANTES de importar. El asistente no pregunta** |
| **Llegaron las categorías malas del Excel** | **Se mapeó la columna CATEGORIA, que traía restos de meses anteriores** | **No mapear TIPO ni CATEGORIA. Dejar que el clasificador proponga** |
| **La app no guardaba en la nube** | **PostgREST exige parámetros con nombre, y la función original recibe `p`** | **Envolturas en `04-rpc.sql` con nombre fijo `p_datos`** |
| **El código de acceso se cortaba** | **`maxlength="6"` y Supabase manda ocho dígitos** | **Acepta de 6 a 10. No fijar el largo: depende del proyecto** |
| **"Tu sesión venció" al meter un código malo** | **Un 401 al canjear se traducía como sesión vencida, imposible: aún no hay sesión** | **`traducir()` recibe contexto y distingue los dos casos** |
| **Las dos columnas se salían de la tarjeta** | **Una columna `1fr` no baja de su contenido mínimo** | **`minmax(0,1fr)` y `min-width:0` en las columnas** |
| **"GasolinaTransporte" pegado, sin recorte** | **`.reg__nombre` es un `<span>`; en elementos en línea `overflow` y `text-overflow` no aplican** | **`display:block` en nombre y meta** |
| **La app dejó de arrancar en producción** | **Se declaró una función `variacion` cuando ya existía otra con ese nombre. En JavaScript gana la última** | **Renombrada a `variacionResumen`. Buscar el nombre antes de declararlo: 5,600 líneas sin módulos comparten un solo espacio de nombres** |

Ese último dejó a la vista la pantalla de rescate diciendo "ábrela en tu navegador" estando en Chrome. **Cuando aparezca ese mensaje en un navegador normal, el problema no es el navegador: es que `pintar()` falló.** Ahora el arranque lo distingue y da un mensaje honesto.

---

## 5. Supabase — dónde quedó

Proyecto **"Revive tu espacio-Finanzas"**, región **East US (Ohio)**, compute Micro. **Todo ejecutado y verificado.**

- Referencia del proyecto: `kbjtzvgafhmiuacyugag`
- Usuario: `armandoalbertosr@gmail.com` · UUID `d318766d-eb84-4603-9dd7-9f8d43ae18c0`
- Cargado: 28 movimientos y 15 cuentas por cobrar. Idempotencia comprobada con una segunda carga: siguieron siendo 28 y 15.

### Verificaciones hechas

| Qué | Resultado |
|---|---|
| RLS en las siete tablas | `rowsecurity = true` en todas |
| Las tres vistas | `security_invoker=true` en todas |
| Políticas | Las siete son `ALL` con `qual` **y** `with_check` sobre `auth.uid()`. Nadie puede grabar a nombre de otro |
| Aislamiento con UUID ajeno | Cero filas en tablas **y** en vistas |
| Acceso anónimo | `permission denied for table movimientos`. El rol `anon` ni siquiera tiene el permiso |

### Archivos

- `supabase/03-limites.sql` — `statement_timeout`, tope de filas por respuesta, y disparadores de tope de 50,000 registros por usuario en `movimientos` y `cuentas_por_cobrar`. **Ejecutado.**
- `supabase/04-rpc.sql` — envolturas `importar_respaldo_json(p_datos jsonb)` y `exportar_respaldo_json()`, con `security invoker`. **Ejecutado.**
- `supabase/01-esquema.sql` y `02-bloques.sql` — **NO están en el repositorio.** Existen solo en el otro equipo. Ver punto 6.

### Lo que hay que recordar

- El SQL Editor corre como servicio, así que `auth.uid()` sale vacío. Hay que declarar la sesión:
  `begin; set local role authenticated; set local request.jwt.claim.sub = 'UUID'; ... commit;`
- **`importar_respaldo` no borra nunca.** Es solo `insert ... on conflict do update`. Consecuencia: lo que borres en la app sigue vivo en la nube y **resucita** al usar "Traer lo que hay". Decisión pendiente en el punto 6.
- La función ignora en silencio los movimientos con monto en cero.
- El correo lo manda el servidor de cortesía de Supabase, con un límite bajo por hora. La plantilla *Magic link or OTP* ya está en español y usa `{{ .Token }}`; si alguna vez vuelve a llegar un enlace en lugar de un código, es que la plantilla se restableció.
- **Región:** no se puede cambiar. Si se queda en Ohio, hay que declarar la transferencia internacional en el aviso de privacidad conforme a la LFPDPPP.
- El CSP ya permite `connect-src 'self' https://kbjtzvgafhmiuacyugag.supabase.co`, en el `<meta>` y en `vercel.json`. **Los dos tienen que coincidir.**

---

## 6. Lo siguiente, en orden

### Inmediato

1. **Rescatar `01-esquema.sql` y `02-bloques.sql`** del otro equipo y hacer commit. Es el único archivo importante sin respaldo, y es justo el que define la seguridad verificada arriba.
2. **Limpiar los datos en la app:** encender el ámbito negocio y reasignar los ~12 movimientos del despacho; corregir las categorías heredadas del Excel; marcar cobradas Bugambilias y Foraway; revisar el ciclo del perfil, que quedó en "diario".
3. **Volver a subir** el respaldo corregido. Debe seguir dando 28 y 15.
4. **Prueba del circuito completo:** entrar desde una ventana de incógnito con el mismo correo y traer los datos. Hasta no hacerlo, el respaldo es una promesa sin verificar.

### Decisión pendiente

5. **¿La nube debe reflejar los borrados?** Hoy no lo hace. Agregarlo son unas veinte líneas en la envoltura: borrar de la nube lo que no venga en el archivo, con la salvaguarda de no borrar nada si la lista llega vacía. El intercambio: la nube se vuelve un espejo fiel del teléfono, pero pierde su condición actual de lugar donde nada se destruye.

### Después

6. **SMTP propio** antes del piloto, en Project Settings → Authentication → SMTP Settings. Con el servidor de cortesía, diez personas intentando entrar el mismo día se topan con el límite y no reciben el correo. Si la A.C. tiene dominio, usarlo: inspira más confianza que `mail.app.supabase.io` cuando le pides a alguien que confíe sus deudas.
7. **Sincronización automática.** Reescribir `Almacen` para que hable con `Nube`. Definir resolución de conflictos: lo más simple y defendible es que gane el más reciente por `id_local`, y nunca borrar en automático. Mientras tanto la regla es **un equipo a la vez, y subir antes de cambiarse**.
8. **Piloto con 10 a 15 personas.** La métrica que importa: ¿siguen capturando en la semana 3? Ahí muere casi toda app de finanzas personales, y ningún backend lo arregla.

### Pendientes menores conocidos

- El PDF conserva el formato anterior; no refleja la estructura del estado financiero con comparativo e indicadores.
- El plan de deudas razona en meses aunque el ciclo sea diario o semanal. Simplificación consciente.
- No hay categorías personalizables. Fijas a propósito.
- No hay modo oscuro.
- En "Mayor a menor", una página puede quedar cargada de un solo lado: si los 25 montos más grandes son gastos, la columna de ingresos dirá "Nada en esta página". Es coherente con el orden, pero se puede paginar por columna si estorba.
- La gráfica de flujo no se dibuja en periodos de más de 62 días: las barras medirían menos de un píxel.

---

## 7. Cómo publicar un cambio

```powershell
cd $HOME\Documents\finanzas
$idx = Get-ChildItem "$HOME\Downloads" -Filter "index*.html" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$idx.Name; $idx.Length      # comparar con el tamaño esperado ANTES de copiar
Copy-Item $idx.FullName .\index.html -Force
git status                  # si dice "nothing to commit", la copia no se hizo
git add .
git commit -m "describe el cambio"
git push
git log --oneline -1        # confirmación de que quedó
```

Vercel redespliega solo. Después, **Ctrl + F5** en la app: el navegador guarda el HTML anterior y sin eso se prueba la versión vieja sin darse cuenta.

Detalle recurrente: el navegador guarda `index (1).html`, `index (2).html`… El comando toma el más reciente. Y si `git status` dice *nothing to commit* con el archivo del tamaño correcto, probablemente ya se publicó: verificar con `git log --oneline -1` antes de repetir la secuencia.

---

## 8. Inventario de archivos

**Raíz** (lo que se publica): `index.html`, `manifest.webmanifest`, `vercel.json`, `icono-192.png`, `icono-512.png`, `apple-touch-icon.png`, `.vercelignore`, `.gitattributes`, `README.md`.

**`docs/`**: `RUTINA-PUSH.md`, `RESPALDO.md`, `PRUEBA-DE-ACEPTACION.md`, `IMPORTAR-EXCEL.md`, `RECOMENDACIONES.md`, `GUIA-PUBLICAR.md`, `MIS-COMANDOS.md`.

**`supabase/`**: `03-limites.sql`, `04-rpc.sql`. **Faltan `01-esquema.sql`, `02-bloques.sql` y el README.**

**`Dockerfile` y `Caddyfile`**: alternativa para Railway. No los usa Vercel.

---

## 9. Lo que no hay que perder de vista

**La instalación en pantalla de inicio no es opcional.** Safari en iPhone borra el almacenamiento de un sitio tras siete días sin visitas. Instalada, no. Un promotor que suelte a alguien sin ver el ícono en su pantalla está garantizando que esa persona pierda lo capturado y no vuelva.

**La nube todavía no es una red de seguridad automática.** Solo guarda cuando alguien le pica al botón. Mientras no haya sincronización, el respaldo manual sigue siendo la única red real.

**Si se hace una versión premium, el corte va en lo que cuesta operar** —servidores, almacenamiento, historial largo— no en lo que la gente necesita para ordenar su dinero. El día que la versión gratuita se sienta mutilada para empujar a la de paga, el proyecto pierde lo que lo hace defendible como herramienta de una asociación civil.

---

## 10. Sobre los datos de Armando

**El Excel `Control_de_ingresos_e_gastos_Agosto2026.xlsx` tiene un problema propio.** La tabla `MonthlyExpenses` abarca casi 80 renglones pero solo 14 traen concepto e importe; los otros 55 conservan TIPO y CATEGORÍA sueltos, restos de meses anteriores. Por eso las gráficas de categoría de esa hoja no describen el mes: *Nómina Semanal* aparece como Café y *Renta de Iconia* como Regalos. Además hay cinco gastos sin TIPO —Zapatos $3,800, Nubarium $1,160, Comida $340, Gasolina $1,200, Café $70— que suman **$6,570**, y por eso la tabla "Gastos por TIPO" da $41,370 cuando el gasto real es $47,940. Los totales generales sí cuadran.

**Las cuentas por cobrar están infladas.** De los $162,477, dos partidas marcadas "Pagadas" suman $55,500 (Bugambilias $35,000 y Foraway $20,500), y la fórmula las suma igual que las abiertas. Lo realmente pendiente son **$106,977**.

**El gasto está sin clasificar.** "Otros" pesa el 84% del gasto del periodo. Mientras siga así, la tarjeta "En qué se fue" no sirve para decidir nada, y la app ya lo dice sola cuando pasa del 40%.

**Las fechas de agosto no son reales.** El Excel no traía columna de fecha, así que el importador repartió los movimientos del 1 al 10. Lo capturado a mano después sí lleva su fecha. De septiembre en adelante la gráfica de flujo será fiel; para agosto, no.
