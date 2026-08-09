# Cómo publicar la app — GitHub + Vercel

Sin terminal, sin comandos. Todo desde el navegador, en la computadora (no desde el celular).

---

## Antes de empezar: revisa tus archivos descargados

En tu carpeta de Descargas debes tener **estos nueve archivos, sueltos**, no dentro de otra carpeta:

```
index.html
manifest.webmanifest
vercel.json
Dockerfile
Caddyfile
icono-192.png
icono-512.png
apple-touch-icon.png
README.md
```

**Dos revisiones que evitan el 90% de los problemas:**

1. **Nombres exactos.** Si el navegador descargó algo como `index (1).html` o `index-1.html`, renómbralo a `index.html`. El nombre debe ser idéntico o la app no carga.
2. **Sin carpeta contenedora.** Si al descomprimir quedó una carpeta `despliegue` con todo adentro, entra a ella. Vas a subir *el contenido*, no la carpeta.

> `Dockerfile` y `Caddyfile` no los usa Vercel. No estorban y sirven si algún día te mudas a Railway. Puedes dejarlos o borrarlos, da igual.

---

## Paso 1 — Crear el repositorio

1. En tu organización **Revive-Tu-Espacio**, botón verde **New repository**.
2. **Repository name:** `finanzas`
3. **Description:** `Herramienta de finanzas personales para las personas que acompaña la asociación`
4. Visibilidad: **Public** está bien. No hay ninguna contraseña ni dato de nadie en estos archivos. Si prefieres Private, Vercel también funciona.
5. **No marques nada más.** Ni "Add a README", ni `.gitignore`, ni licencia. Si marcas algo, el repositorio nace con archivos y el siguiente paso se complica.
6. **Create repository**.

---

## Paso 2 — Subir los archivos

Vas a ver una pantalla que dice "Quick setup" con varios comandos. Ignóralos todos.

1. Busca la liga **uploading an existing file** (en la frase "…or upload an existing file"). Haz clic ahí.
2. Selecciona los nueve archivos y **arrástralos** a la zona punteada. Todos juntos, de un jalón.
3. Espera a que terminen de subir. Deben aparecer listados los nueve.
4. Abajo, en el recuadro de mensaje, escribe: `Primera versión de la app de finanzas`
5. Botón verde **Commit changes**.

Ya está tu código en GitHub.

---

## Paso 3 — Conectar Vercel

1. Entra a [vercel.com](https://vercel.com) con tu cuenta.
2. **Add New… → Project**.
3. Si no aparece la organización Revive-Tu-Espacio en la lista, haz clic en **Adjust GitHub App Permissions** (o *Configure GitHub App*) y concédele acceso a esa organización. Es un paso que confunde a muchos: Vercel no ve tus organizaciones hasta que se lo autorizas.
4. Localiza el repositorio `finanzas` y presiona **Import**.

---

## Paso 4 — Configurar (spoiler: no hay nada que configurar)

Vercel te va a mostrar una pantalla de opciones. **Déjala tal cual:**

| Campo | Qué hacer |
|---|---|
| Framework Preset | **Other** — si detecta otra cosa, cámbialo a Other |
| Root Directory | Déjalo en `./` |
| Build Command | **Vacío.** Si trae algo, bórralo |
| Output Directory | **Vacío.** Si trae algo, bórralo |
| Install Command | **Vacío** |
| Environment Variables | Ninguna. No hay claves ni base de datos |

Presiona **Deploy**. Tarda menos de un minuto.

---

## Paso 5 — Tu liga

Cuando termine sale una pantalla de felicitación con la URL, algo como:

```
https://finanzas-abc123.vercel.app
```

Ábrela en la computadora. Debe aparecer el formulario de alta, no la pantalla que dice "Ábrela en tu navegador". Si ves esa pantalla, algo salió mal con el nombre del archivo: revisa que se llame exactamente `index.html`.

**Para ponerle un nombre bonito:** en el proyecto, **Settings → Domains**. Ahí puedes cambiar el subdominio a algo como `finanzas-revive.vercel.app`, gratis. Si la asociación ya tiene dominio propio, en esa misma pantalla agregas `finanzas.revivetuespacio.org` y Vercel te dice qué registro capturar en tu DNS.

---

## Paso 6 — Probar en el celular de verdad

Ahora sí, manda la liga a tu WhatsApp y ábrela desde el teléfono.

**La prueba que importa:**

1. Da de alta un perfil y registra dos o tres gastos.
2. **Cierra el navegador por completo.** No lo dejes en segundo plano: ciérralo.
3. Vuelve a abrir la liga.
4. Tus movimientos deben seguir ahí.

Si sobreviven, la app está funcionando como debe y ya la puedes repartir.

**Instálala en la pantalla de inicio** para ver el resultado final:

- **iPhone (Safari):** botón de compartir → *Agregar a inicio*
- **Android (Chrome):** menú de tres puntos → *Agregar a la pantalla principal*

Debe quedar el ícono de la hoja verde y abrirse en pantalla completa, sin barra de direcciones.

---

## Cómo actualizar después

Cuando quieras cambiar algo: en GitHub entras al archivo, botón del lápiz, editas, **Commit changes**. Vercel redespliega solo en menos de un minuto y todos ven la versión nueva sin reinstalar nada.

Los datos que la gente ya capturó **no se borran** con una actualización: viven en su teléfono, no en el servidor.

---

## Si algo falla

| Lo que ves | Qué revisar |
|---|---|
| Pantalla "Ábrela en tu navegador" en la computadora | El archivo no se llama `index.html`, o quedó dentro de una subcarpeta en el repo |
| Error 404 de Vercel | Los archivos están dentro de una carpeta. En GitHub deben verse en la raíz del repositorio |
| El ícono no aparece al instalar | Faltó subir alguno de los tres `.png` |
| Los datos se borran al cerrar | Estás abriendo el archivo descargado, no la liga `https://` |
| Vercel no ve el repositorio | Falta autorizar la organización en Adjust GitHub App Permissions |
