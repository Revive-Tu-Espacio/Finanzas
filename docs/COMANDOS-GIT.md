# Comandos para aplicar los cambios desde la terminal

Suponiendo que el repositorio es `Revive-Tu-Espacio/finanzas`. Si le pusiste otro nombre, cámbialo en el primer comando y lo demás sigue igual.

Elige el bloque de tu sistema. **No mezcles los dos.**

---

## Antes de empezar

**1. Verifica que tengas git:**

```bash
git --version
```

Si responde con un número de versión, adelante. Si dice que el comando no existe, instálalo desde [git-scm.com/downloads](https://git-scm.com/downloads) y vuelve a abrir la terminal.

**2. Descarga los archivos nuevos.** Necesitas en tu carpeta de Descargas:

- `index.html` (la versión con ciclo diario y campana de alertas)
- `RECOMENDACIONES.md`
- `GUIA-PUBLICAR.md`

El `.vercelignore` **no lo descargues**: los navegadores suelen renombrar archivos que empiezan con punto y te lo guardarían como `vercelignore.txt`. Los comandos de abajo lo crean directamente.

**3. Identifícate en git** (solo la primera vez en esa computadora):

```bash
git config --global user.name "Tu Nombre"
git config --global user.email "tucorreo@ejemplo.com"
```

---

## Windows — PowerShell

Abre PowerShell (tecla Windows, escribe `powershell`, Enter) y pega bloque por bloque.

### Paso 1 — Clonar el repositorio

```powershell
cd $HOME\Documents
git clone https://github.com/Revive-Tu-Espacio/finanzas.git
cd finanzas
```

### Paso 2 — Reemplazar la app y acomodar la documentación

```powershell
$D = "$HOME\Downloads"

Copy-Item "$D\index.html" . -Force

New-Item -ItemType Directory -Force -Path docs | Out-Null
Copy-Item "$D\RECOMENDACIONES.md" docs\ -Force
Copy-Item "$D\GUIA-PUBLICAR.md"   docs\ -Force
```

### Paso 3 — Crear el `.vercelignore`

```powershell
@"
# Archivos que viven en el repositorio pero NO se publican en la web.
docs/
GUIA-PUBLICAR.md
RECOMENDACIONES.md
Dockerfile
Caddyfile
.DS_Store
Thumbs.db
*.log
"@ | Set-Content -Path .vercelignore -Encoding UTF8
```

> Nota: aquí se excluyen los archivos por nombre en vez de usar `*.md`, para que el `README.md` siga visible en GitHub y quede fuera del sitio publicado sin comprometer nada más.

### Paso 4 — Revisar antes de subir

```powershell
git status
```

Debes ver `index.html` como modificado, y `docs/` y `.vercelignore` como archivos nuevos. Si aparece algo que no esperabas, párate aquí y revísalo.

### Paso 5 — Publicar

```powershell
git add .
git commit -m "feat: ciclo diario, campana de alertas y capacidad de endeudamiento"
git push
```

---

## macOS o Linux

```bash
cd ~/Documents
git clone https://github.com/Revive-Tu-Espacio/finanzas.git
cd finanzas

D=~/Downloads
cp "$D/index.html" .

mkdir -p docs
cp "$D/RECOMENDACIONES.md" docs/
cp "$D/GUIA-PUBLICAR.md"   docs/

cat > .vercelignore <<'FIN'
# Archivos que viven en el repositorio pero NO se publican en la web.
docs/
GUIA-PUBLICAR.md
RECOMENDACIONES.md
Dockerfile
Caddyfile
.DS_Store
Thumbs.db
*.log
FIN

git status
```

Si `git status` se ve bien:

```bash
git add .
git commit -m "feat: ciclo diario, campana de alertas y capacidad de endeudamiento"
git push
```

---

## Si el `push` te pide usuario y contraseña

GitHub ya no acepta contraseñas por terminal. Tienes dos caminos:

**Opción A — Token de acceso personal.** En GitHub: foto de perfil → Settings → Developer settings → Personal access tokens → Tokens (classic) → Generate new token. Marca solo el permiso `repo`. Cuando la terminal te pida usuario, escribe tu usuario de GitHub; cuando pida contraseña, **pega el token**. No se ve mientras lo pegas, es normal.

**Opción B — GitHub CLI**, más cómodo si vas a hacer esto seguido:

```bash
gh auth login
```

Sigue las instrucciones en pantalla y después el `git push` funciona sin pedirte nada.

---

## Verificar que quedó

1. Entra a tu repositorio en GitHub. Debe aparecer la carpeta `docs/` y el archivo `.vercelignore`.
2. En Vercel, la pestaña Deployments muestra un despliegue nuevo en curso. Tarda menos de un minuto.
3. Abre tu liga en el celular. Al dar de alta un perfil, la primera opción de ciclo debe decir **Diario**, y arriba a la derecha debe verse la campana.
4. Comprueba que `tu-liga.vercel.app/RECOMENDACIONES.md` ya **no** cargue.

---

## Para los cambios que vengan

Ya con el repositorio clonado, cada actualización es más corta. Reemplazas los archivos que cambien y:

```bash
cd ~/Documents/finanzas     # en Windows: cd $HOME\Documents\finanzas
git pull
# ...copias los archivos nuevos...
git add .
git commit -m "describe aquí qué cambió"
git push
```

El `git pull` del inicio importa: si alguna vez editas algo desde la web de GitHub, ese comando trae esos cambios antes de que subas los tuyos y evita un conflicto.

---

## Si algo sale mal

| Mensaje | Qué significa | Qué hacer |
|---|---|---|
| `fatal: repository not found` | El nombre del repo o de la organización está mal escrito, o no tienes acceso | Copia la URL exacta desde el botón verde **Code** en GitHub |
| `Updates were rejected` | Hay cambios en GitHub que no tienes localmente | `git pull` y luego repite el `push` |
| `nothing to commit` | Los archivos que copiaste son idénticos a los que ya estaban | Revisa que hayas copiado desde Descargas y no una versión vieja |
| `Permission denied` | Falló la autenticación | Usa el token o `gh auth login` de la sección anterior |
| Vercel no redespliega | El push no llegó, o el proyecto no está conectado a esa rama | Revisa en GitHub que el commit aparezca en `main` |
