# Cierre de sesión — 29 de agosto de 2026

**Asunto:** abonar a una deuda desde el módulo de deudas, viendo bajar el saldo.
**Resultado:** implementado y publicado.
**Commit:** `feat(deudas): abonar a una deuda desde panel lateral con registro opcional del gasto`

---

## Lo que se pidió

Que cada deuda tuviera un icono para abonarle, y que el abono disminuyera el
saldo. Con la mejor experiencia posible para la persona usuaria, sencilla e
intuitiva, y usando el modal que entra desde la derecha.

Antes de esta sesión la única forma de reflejar un pago era editar la deuda
borrándola y recreándola con el saldo nuevo, o llevar la cuenta fuera de la
app. Las metas de ahorro ya tenían "Abonar"; las deudas no.

## Qué se cambió

Cinco piezas en `index.html`. 268,320 → 273,137 bytes (+4,817). El punto de
partida fue el `index.html` de `main` en `b8ea4df`, descargado directo del
repo para garantizar que las ediciones cayeran sobre la versión publicada.

**1. Icono `abono` en el catálogo SVG.** Una flecha que baja hacia una
línea: la deuda que disminuye. Mismo trazo (1.8, redondeado) que el resto.

**2. Botón de abonar en cada fila de deuda.** Junto al bote de basura, con
la misma zona táctil de 44 px y `aria-label`, pero con *hover* verde
(`--verde-claro` / `--verde-bosque`): es una acción positiva y no debe
parecerse a borrar. La línea de detalle de la fila ahora muestra
"Ya bajaste $X" cuando la deuda acumula abonos (`d.abonado`).

**3. `panelAbonoDeuda()`.** Usa `abrirPanel` — entra desde la derecha, y la
lista de deudas queda visible detrás mientras la persona decide. Contiene:

- El saldo actual, en grande.
- El monto **prellenado con el pago mensual** de la deuda (topado al
  saldo). El caso común se resuelve con un tap.
- Botón "Liquidarla completa ($X)" que llena el campo con el saldo total.
- Fecha, con tope en hoy.
- Checkbox marcado por defecto: **"Registrarlo también como gasto"**. Crea
  un movimiento tipo gasto, categoría `deuda`, nota "Abono a {nombre}", con
  el ámbito activo. Se puede desmarcar si la persona ya capturó ese pago a
  mano — está ahí para evitar el doble conteo, que era el riesgo real de
  registrarlo siempre en automático como hace el flujo de cobros.
- Validación: monto obligatorio y no mayor al saldo. Si pagó de más
  (intereses), el mensaje sugiere registrar la diferencia como gasto aparte.

**4. Liquidación automática.** Si el abono deja el saldo en cero, la deuda
sale del plan con el aviso "¡Liquidaste esta deuda! Una menos." Si queda
saldo, el aviso lo dice: "Abono registrado. Debes $X."

**5. Delegación.** El manejador de `data-abonar-deuda` quedó junto al
`data-abonar` de metas, dentro de la escucha global de `click`. Cero
escuchas por elemento, como manda la arquitectura.

Antes de escribir nada se verificó que `panelAbonoDeuda`, el icono `abono` y
`data-abonar-deuda` no existieran ya en el archivo — la lección de
`variacion`. También que `avisar()` usa `textContent` (el nombre de la deuda
no puede inyectar HTML) y que la categoría `deuda` ("Pago de deuda", ámbito
"ambos") existe como categoría de gasto.

## Incidente durante la publicación

La publicación se hizo desde una **segunda máquina** (`C:\Users\arman`), y
dejó dos lecciones que ya están en `CONTINUIDAD.md`:

**La copia local estaba atrasada.** `git pull` la movió de `6abcccf` a
`b8ea4df` — varios commits, incluidos los `.sql` y la documentación del 11
de agosto. Trabajar sin ese `pull` habría terminado en conflicto o en
revertir trabajo.

**La verificación de bytes atrapó un push malo.** En Descargas había doce
archivos `index*.html` de sesiones distintas, y el que se llamaba
`index.html` a secas pesaba 26,457 bytes — una versión vieja e inservible.
Se copió al repo antes de verificar. `Get-ChildItem | Select-Object Length`
lo delató, `git restore index.html` reparó el repo, y el archivo correcto
resultó ser `index (10).html` (273,137 bytes). El hábito de verificar el
tamaño antes de `git add` existe exactamente para esto, y esta vez pagó la
renta. Las descargas viejas se deben limpiar para que no se repita.

## Verificación

En la app desplegada en Vercel, el ciclo completo sobre una deuda de prueba:

1. El botón de la flecha aparece en cada fila, junto al bote.
2. El panel entra desde la derecha con el pago mensual ya sugerido.
3. Un abono parcial baja el saldo, la fila muestra "Ya bajaste $X", y el
   gasto aparece en Movimientos con categoría "Pago de deuda".
4. "Liquidarla completa" deja el saldo en cero y la deuda sale del plan.

## Decisión que queda registrada

**Liquidar una deuda la elimina del dispositivo, no de la nube.** Es el
mismo comportamiento que ya tenía el botón de quitar deuda, así que no se
introdujo ningún riesgo nuevo — pero el respaldo sigue siendo *upsert* puro
y "Traer lo que hay en la nube" puede revivir una deuda liquidada. Este caso
se sumó al riesgo 2 de `CONTINUIDAD.md`. La decisión de fondo (marcas de
borrado o reemplazo total) sigue pendiente y cada función nueva que borra
registros la vuelve más urgente.

## Sigue pendiente

Por gravedad, detallado en `CONTINUIDAD.md`:

1. **Los `.sql` 01 y 02 fuera del repo.** El único de la lista que no se
   recupera solo. (03 y 04 ya están.)
2. Sincronización de borrados con la nube — ahora con un caso más.
3. SMTP propio antes de cualquier piloto.
4. Advertencias en la importación desde Excel.
5. `manifest-src` en la CSP, en los dos lugares.
