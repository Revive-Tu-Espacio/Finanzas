# Mis finanzas — Revive tu Espacio A.C.

Herramienta de control de finanzas personales. Un solo archivo HTML, sin servidor, sin base de datos y sin cuentas: cada persona guarda su información en su propio dispositivo.

## Contenido del repositorio

```
index.html              La aplicación completa
manifest.webmanifest    Para que se instale en la pantalla de inicio
icono-192.png           Ícono de la asociación
icono-512.png
apple-touch-icon.png
Caddyfile               Configuración del servidor estático
Dockerfile              Imagen de despliegue
```

No hay claves, tokens ni credenciales en ningún archivo. **El repositorio puede ser público sin riesgo.**

---

## Subirlo a GitHub

```bash
cd despliegue
git init
git add .
git commit -m "feat: MVP de finanzas personales para Revive tu Espacio A.C."
git branch -M main
git remote add origin https://github.com/TU-USUARIO/revive-finanzas.git
git push -u origin main
```

---

## Desplegar en Railway

1. En Railway: **New Project → Deploy from GitHub repo** y elige el repositorio.
2. Railway detecta el `Dockerfile` y construye con él. No necesitas configurar nada más: no hay variables de entorno que definir.
3. Cuando termine, entra a **Settings → Networking → Generate Domain**. Ahí sale tu URL `xxx.up.railway.app`.
4. Abre esa URL en el celular. Esa es la liga que se reparte por WhatsApp.

Si prefieres saltarte el `Dockerfile`, Railway también detecta sitios estáticos por sí solo y los sirve con Caddy. Funciona, pero entonces los encabezados de seguridad del `Caddyfile` no se aplican. Con el `Dockerfile` mandas tú.

### Para probarlo antes en tu computadora

```bash
docker build -t revive-finanzas .
docker run --rm -p 8080:8080 revive-finanzas
# abre http://localhost:8080
```

### Dominio propio

En **Settings → Networking → Custom Domain**, agrega por ejemplo `finanzas.revivetuespacio.org` y captura el CNAME que Railway te indique en tu proveedor de DNS. Railway emite el certificado solo.

---

## Una nota sobre la plataforma

Railway funciona bien para esto, pero está pensado para aplicaciones con proceso corriendo, y aquí solo se entregan archivos. Vas a pagar por un contenedor encendido las 24 horas para servir 70 KB.

Para este caso concreto, **GitHub Pages sale gratis y sin contenedor**: mismo repositorio, Settings → Pages → rama `main`, y queda publicado. Cloudflare Pages y Vercel también son gratuitos para sitios estáticos y traen CDN.

Si de todos modos prefieres Railway porque ahí tienes todo lo demás y quieres un solo tablero, es una razón válida. Solo que sea decisión, no accidente.

---

## Después de publicar

Enseña a la gente a instalarla, porque cambia por completo el uso:

- **iPhone:** abrir la liga en Safari → botón de compartir → *Agregar a inicio*
- **Android:** abrir en Chrome → menú de tres puntos → *Agregar a la pantalla principal*

Queda con el ícono de la hoja y abre en pantalla completa, sin barra del navegador. Además, así el navegador protege mejor los datos guardados.

## Actualizaciones

Cambias `index.html`, haces `git push`, y Railway redespliega solo. Todo el mundo ve la versión nueva la próxima vez que abra la app. Nadie tiene que reinstalar nada.

**Los datos de cada persona no se tocan** con un redespliegue: viven en su navegador, no en el servidor. Eso también significa que si alguien borra los datos de navegación o cambia de teléfono, pierde su historial. Por eso la app trae la opción de descargar respaldo en Ajustes: vale la pena que los promotores lo recuerden en cada sesión.
