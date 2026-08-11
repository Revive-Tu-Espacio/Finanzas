# Cierre de sesión — 11 de agosto de 2026

**Asunto:** "Guardar mis datos ahora" mostraba "Algo falló" en cada intento.
**Resultado:** resuelto y publicado.
**Commit:** `fix(nube): leer respuesta vacia de RPC y mostrar el error real`

---

## Lo que se reportó

Al tocar "Guardar mis datos ahora" en Ajustes, la app mostraba
*"Algo falló. Si se repite, exporta tu respaldo."* De forma consistente. Se
descargó el respaldo local como medida preventiva antes de investigar.

## Lo que en realidad pasaba

**El guardado funcionaba desde el principio.** La petición a Supabase salía,
el servidor respondía 200 OK y los datos quedaban almacenados. El fallo
ocurría después, al leer la respuesta: `await r.json()` sobre un cuerpo que
no podía interpretarse lanzaba una excepción que nadie atrapaba, se
convertía en `unhandledrejection`, y la red de seguridad global mostraba el
aviso genérico.

Es decir: se estaba reportando como error algo que había salido bien.

## Cómo se llegó ahí

El recorrido, porque el orden es reutilizable:

1. **Network mostró `0 / 7 requests`** con el filtro Fetch/XHR. Descartaba
   un problema de red, pero la lectura fue engañosa: el filtro estaba mal
   puesto y la llamada sí existía.
2. **Consola: `401` en `importar_respaldo_json`.** Apuntaba a token vencido.
3. **Cerrar sesión y volver a entrar no arregló nada.** Descartaba la
   hipótesis del token expirado.
4. **Network con el filtro correcto: `200 OK`.** El giro. La llamada
   funcionaba. El 401 anterior era un error viejo que había quedado en la
   consola sin limpiar.
5. **Tres llamadas seguidas** —dos `importar`, una `exportar`— revelaron que
   `refrescar()` estaba haciendo su trabajo: 401, renovar token, reintentar,
   200.
6. **Revisión del código.** El texto "Algo falló" aparece en exactamente dos
   lugares del archivo: los dos manejadores globales del final. No podía
   venir de `Nube`, porque esa capa nunca lanza. Por eliminación, era una
   excepción no atrapada.

Buena parte del ruido vino de errores de extensiones del navegador
(`200.js`, `ObjectMultiplex`, `contentscript.js`) mezclados con los de la
app. En un proyecto de un solo archivo, todo lo que no apunte a `(index)` es
descartable.

## Qué se cambió

Tres ediciones en `index.html`, aplicadas con un script de PowerShell que
verificaba una coincidencia exacta por reemplazo antes de tocar nada.
267,694 → 268,320 bytes.

**1. `Nube.rpc()` — leer el cuerpo sin tronar.** Se sustituyó
`return bien(await r.json())` por una lectura con `r.text()` dentro de
`try/catch`, que devuelve `null` si el cuerpo viene vacío o no es JSON
válido. PostgREST responde 200 con cuerpo vacío cuando una función no
devuelve nada, y ese caso no estaba contemplado.

**2. `subirALaNube()` — no inventar ceros.** Antes reportaba
"Guardado: 0 movimientos" cuando no había cuerpo que leer, lo cual es peor
que no decir nada. Ahora distingue: si vienen datos los muestra, si no, dice
"Guardado en la nube."

**3. Manejadores globales — decir qué falló.** Los dos
`window.addEventListener` del final mostraban un texto fijo. Ahora extraen
el mensaje real de la excepción, lo muestran recortado a 90 caracteres, y
además lo registran completo con `console.error`.

Este tercer cambio no arregla el bug de hoy: arregla el diagnóstico de todos
los que vengan.

## Verificación

En la app desplegada en Vercel, "Guardar mis datos ahora" respondió:

> **Guardado: 38 movimientos y 15 por cobrar.**

Vale la pena notar que la función SQL **sí** devolvía el conteo. La hipótesis
de trabajo era que el cuerpo venía vacío; resultó ser que en algún punto del
ciclo —probablemente el reintento tras el 401— la respuesta no era
interpretable. El `try/catch` cubrió el caso de todas formas, y el mensaje
ahora confirma con números que los datos llegaron.

## Lo que deja esta sesión

**Un `catch` sin `console.error` es una trampa.** El diagnóstico requirió
siete capturas de pantalla para descubrir que nada estaba roto. Con el
mensaje real desde el primer intento, habría tomado dos minutos. Es la
segunda vez que este proyecto paga el mismo costo: antes fue la pantalla de
rescate que culpaba al visor de WhatsApp.

**Un 200 OK no significa que la aplicación funcionó.** Significa que el
servidor hizo su parte. Lo que el cliente haga con esa respuesta es otro
territorio, y es donde estaba el error.

**Limpiar la consola antes de reproducir un fallo.** El 401 viejo mandó la
investigación por un camino equivocado durante varios pasos, y solo el orden
relativo de los mensajes (el `403` del logout aparecía *después*) delató que
era anterior.

## Sigue pendiente

Por gravedad, detallado en `CONTINUIDAD.md`:

1. **Los `.sql` fuera del repo.** El único de la lista que no se recupera
   solo.
2. Sincronización de borrados con la nube.
3. SMTP propio antes de cualquier piloto.
4. Advertencias en la importación desde Excel.
5. `manifest-src` en la CSP.
