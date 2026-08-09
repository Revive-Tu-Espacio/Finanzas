# Servidor estático mínimo. Sin Node, sin dependencias, sin build.
# La imagen final pesa ~50 MB y arranca en menos de un segundo.
FROM caddy:2-alpine

COPY Caddyfile /etc/caddy/Caddyfile
COPY index.html manifest.webmanifest /srv/
COPY icono-192.png icono-512.png apple-touch-icon.png /srv/

# Railway asigna el puerto en tiempo de ejecución mediante $PORT;
# este EXPOSE es solo para correrlo en local.
EXPOSE 8080

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
