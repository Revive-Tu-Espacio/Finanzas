# Continuidad — Finanzas · Revive tu Espacio A.C.

Documento de traspaso. Sirve para dos escenarios: que alguien más tome el
proyecto, o que quien lo escribió vuelva dentro de unos meses y ya no
recuerde por qué las cosas están como están.

Última actualización: 11 de agosto de 2026.

---

## 1. Qué es

Aplicación de control de finanzas personales para las personas que acompaña
Revive tu Espacio A.C. La premisa que gobierna todas las decisiones técnicas:

> Los datos viven en el dispositivo de la persona. La nube es una copia
> opcional. La asociación no ve lo que nadie registra.

De ahí se derivan las restricciones de la sección 3. Cuando haya que decidir
algo y no esté escrito aquí, esa frase es el criterio.

## 2. Dónde está cada coso

| Qué | Dónde |
|---|---|
| Repositorio | `github.com/Revive-Tu-Espacio/Finanzas` |
| Despliegue | Vercel, conectado al repo (`main` → producción) |
| Aplicación | `finanzas-flax-pi.vercel.app` |
| Backend | Supabase, proyecto `kbjtzvgafhmiuacyugag` |
| Copia local de trabajo | `C:\Users\TechTailor\Documents\finanzas` (Windows / PowerShell) |
| Todo el código | `index.html` — un solo archivo, ~268 KB |

No hay proceso de compilación. No hay `package.json`, ni `node_modules`, ni
framework. El archivo que está en el repo es exactamente el que corre en el
navegador. Editar y hacer push es todo el flujo.

## 3. Restricciones que no se negocian

Estas no son preferencias de estilo. Cada una responde a la premisa de la
sección 1, y romperlas rompe el producto.

**Funciona sin conexión.** No se carga ninguna librería externa, ni por CDN
ni de otro modo. Por eso el generador de `.xlsx` está escrito a mano en el
propio archivo (ZIP + XML), por eso el PDF se genera con `window.print()` en
vez de una librería, y por eso las gráficas son SVG en línea.

**No se usa la librería JS de Supabase.** Todo son llamadas REST directas
con `fetch`. Incluirla obligaría a aflojar `script-src` en la CSP, que es
justo la protección que evita que un script ajeno lea los datos de la
persona.

**La CSP está declarada en dos lugares** y hay que mantener ambos
sincronizados: `vercel.json` y la etiqueta `<meta http-equiv>` del `<head>`.

**La nube es aditiva.** Todo lo que la app hace tiene que funcionar sin
sesión. Quien nunca active la nube no debe ver nunca un correo, un código ni
un error de red.

**La llave anónima de Supabase va incrustada en el código, a propósito.** Lo
que protege los datos no es esconderla: es la RLS de la base. La
`service_role` **nunca** aparece en el cliente.

## 4. Arquitectura, en una página

### Almacenamiento local

El objeto `Almacen` (sección 1 del script) aísla toda la persistencia. Tiene
tres modos con degradación: `window.storage` → `localStorage` → memoria. Si
cae a memoria, la app avisa a la persona que exporte su respaldo.

Clave: `rte_finanzas_v1`. Todo el estado es un solo objeto JSON.

Al arrancar se pide `navigator.storage.persist()`, porque Safari en iOS borra
el almacenamiento de un sitio tras siete días sin visitas — exactamente el
escenario de quien captura una semana y luego se ocupa.

### Nube

El objeto `Nube` (sección 1b) encapsula autenticación y respaldo remoto.

- Autenticación por código de un solo uso al correo (OTP). Sin contraseñas.
- Sesión guardada en `rte_finanzas_sesion_v1`: `acceso`, `refresco`, `correo`.
- Dos funciones RPC: `importar_respaldo_json` (sube) y
  `exportar_respaldo_json` (baja).
- La función `rpc()` renueva el token automáticamente ante un 401 y
  reintenta una vez. Si el reintento también falla, borra la sesión y pide
  entrar de nuevo.

**Contrato de errores.** Toda función pública de `Nube` devuelve una de dos
formas y nunca lanza excepción:

```js
{ ok: true,  datos }
{ ok: false, codigo, mensaje }
```

Códigos: `RED`, `LIMITE`, `CREDENCIAL`, `SESION`, `SERVIDOR`. Si se agrega
una función nueva a `Nube`, tiene que respetar este contrato.

### Base de datos

Siete tablas con RLS activa, tres vistas con `security_invoker`, timeouts de
sentencia, topes de filas y disparadores que limitan la frecuencia de
inserción.

**Las funciones RPC deben usar parámetros nombrados** (`p_datos`, no `p`).
PostgREST los resuelve por nombre; con un parámetro posicional la llamada
falla con 404 y el mensaje no es evidente.

### Interfaz

Un único `pintar()` redibuja `#vista` según `vistaActual`. Los eventos se
manejan por delegación en tres escuchas globales (`click`, `submit`,
`input`), no con escuchas por elemento.

Dos contenedores modales, con propósitos distintos:

- **Hoja** (`abrirHoja`): sube desde abajo. Para formularios y decisiones.
- **Panel** (`abrirPanel`): entra desde la derecha. Para detalle, cuando
  conviene que el contexto siga visible detrás.

## 5. Cómo se publica un cambio

Desde PowerShell, en la carpeta del proyecto:

```powershell
git status                    # debe estar limpio antes de empezar
# ... editar index.html ...
git status                    # debe mostrar SOLO index.html
git add index.html
git commit -m "fix(alcance): descripcion en una linea"
git push
git log --oneline -1          # confirmar
```

Después hay que **probar en la app desplegada**, no en local. Dale un par de
minutos a Vercel.

Antes de hacer commit, verifica el tamaño del archivo:

```powershell
Get-ChildItem index.html | Select-Object Length
```

Un cambio de tres líneas que altera el tamaño en miles de bytes significa
que algo se duplicó o se borró de más.

### Ediciones por script

Para cambios quirúrgicos en un archivo de 268 KB es más seguro un script de
PowerShell que editar a mano. El patrón que funcionó:

1. Copiar el original a `.bak`.
2. Para cada reemplazo, **contar las coincidencias primero**. Si no hay
   exactamente una, abortar sin tocar nada.
3. Escribir con `UTF8Encoding($false)` — sin BOM.
4. Imprimir el tamaño antes y después.
5. Borrar el `.bak` y el script antes del commit, o se van al repo.

Los acentos en el script se escriben como `[char]0xF3` en vez de literales,
para que el `.ps1` sea ASCII puro y PowerShell 5.1 no meta mojibake.

## 6. Riesgos abiertos, por gravedad

### 1. Los archivos SQL no están en el repo — CRÍTICO

`supabase/01-esquema.sql` y `supabase/02-bloques.sql` existen únicamente en
otra máquina. Nunca se han subido.

Si esa máquina se pierde, hay que reconstruir a mano las siete tablas, sus
políticas RLS, las tres vistas, los timeouts, los topes de filas, los
disparadores de throttle y las dos funciones RPC. Reconstruir eso desde la
consola de Supabase es posible, pero lento y propenso a dejar una política
mal puesta — y una política RLS mal puesta es una fuga de datos entre
personas usuarias.

**Es el único riesgo de esta lista que no se recupera solo.** Todo lo demás
son molestias.

Acción: copiar ambos archivos desde la otra máquina, ponerlos en
`supabase/` y hacer commit. Es media hora de trabajo que evita un desastre.

### 2. Los borrados no se propagan a la nube

El respaldo hace *upsert* puro. Cada registro conserva su identificador, así
que subir dos veces actualiza en vez de duplicar — eso está bien. Pero un
movimiento borrado en el dispositivo sigue existiendo en la nube, y "Traer
lo que hay en la nube" lo revive.

Con 38 movimientos aún es manejable a mano. Conviene decidirlo antes de que
crezca. Dos caminos:

- Marca de borrado (*tombstone*): el registro se marca como eliminado en vez
  de desaparecer, y el respaldo la propaga.
- Reemplazo total: `importar_respaldo_json` borra todo lo del usuario y
  vuelve a insertar. Más simple, pero peligroso si el respaldo llega
  incompleto.

### 3. SMTP sin configurar

El servidor de correo de cortesía de Supabase limita agresivamente el envío.
Con varias personas pidiendo su código al mismo tiempo, algunas
sencillamente no lo reciben, y desde la app se ve como un error inexplicable.

Hay que configurar un SMTP propio **antes de cualquier piloto**.

### 4. Importación desde Excel: dos trampas conocidas

- Si no se activa el ámbito de negocio antes de importar, todo aterriza en
  personal sin aviso.
- El mapeo de la columna CATEGORIA ha traído datos de meses anteriores.

Ambas merecen al menos una advertencia visible en el asistente.

### 5. `manifest-src` bloqueado por la CSP

La consola reporta que `/manifest.webmanifest` se bloquea porque
`manifest-src` no está declarado y cae al `default-src 'none'`. Afecta la
instalación como aplicación en el teléfono. Menor, pero se arregla en una
línea — en los **dos** lugares donde vive la CSP.

## 7. Lecciones que costaron caro

**Los nombres de función colisionan en silencio.** Con todo el código en un
archivo, declarar `function variacion()` cuando ya existía otra con ese
nombre no produce ningún error: la segunda simplemente pisa a la primera y
algo lejano deja de funcionar. Antes de nombrar una función nueva, búscala.
El incidente concreto: una `variacion` nueva pisó la de la línea 3758; se
renombró a `variacionResumen`.

**El mensaje amable tapa el problema.** Dos veces ha pasado lo mismo. Una
pantalla de rescate genérica hacía creer que el archivo se estaba abriendo
dentro de WhatsApp cuando el problema era otro. Un aviso de "Algo falló"
escondía que el guardado en la nube funcionaba perfectamente. En ambos casos
el diagnóstico solo avanzó cuando se pudo ver el error real.

Regla: un mensaje para la persona puede ser amable, pero **siempre** debe ir
acompañado de un `console.error` con el detalle. Nunca un `catch` vacío.

**El largo del campo OTP debe coincidir con lo que manda el proveedor.**
Supabase envía códigos de ocho dígitos. Un `maxlength="6"` truncaba el
código en silencio y la credencial llegaba corrupta al servidor. El campo
acepta hoy de 6 a 10.

**Un 200 OK no significa que la app funcionó.** El error puede estar en cómo
se lee la respuesta. Ver la sección 8.

## 8. Cómo diagnosticar cuando algo falla

El orden importa. Cada paso descarta una familia entera de causas.

**Paso 1 — ¿Salió la petición?**
DevTools (F12) → pestaña Network → filtrar por el nombre de la llamada →
reproducir el fallo.

- No aparece nada → el error es de JavaScript, antes de llamar. Ir a
  Console.
- Aparece → seguir al paso 2.

**Paso 2 — ¿Qué contestó el servidor?**
Clic en la línea → columna Status.

| Código | Significa |
|---|---|
| 200 | Funcionó. Si aun así falla, el error está en cómo se lee la respuesta. |
| 400 | Petición mal formada, o un disparador la rechazó. Ver Response. |
| 401 | Token vencido o ausente. |
| 403 | Una política RLS bloqueó. |
| 404 | Función no encontrada: revisar nombre y parámetros nombrados. |
| 429 | Límite de frecuencia. |
| 504 / `57014` | Se rebasó el `statement_timeout`. |

**Paso 3 — Leer la respuesta.** Pestaña Response. Si viene vacía con un 200,
la función SQL no devuelve nada y cualquier `.json()` sobre ella truena.

**Paso 4 — Consola, filtrando el ruido.** Limpiar con 🚫 antes de
reproducir, o los errores viejos confunden. En este proyecto, todo lo que
venga de `contentscript.js`, `200.js` u `ObjectMultiplex` son extensiones
del navegador, no la app. La app es un solo archivo: si el error no apunta a
`(index)`, no es tuyo.

## 9. Antes de un piloto con personas reales

- [ ] Los `.sql` en el repo
- [ ] SMTP propio configurado
- [ ] Decidida la sincronización de borrados
- [ ] Advertencias en el asistente de importación
- [ ] `manifest-src` en la CSP, en los dos lugares
- [ ] Probado el ciclo completo en un teléfono real: alta, captura, respaldo,
      cambio de dispositivo, restauración
