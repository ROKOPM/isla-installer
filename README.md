# ISLA de Datos Urbanos Installer

Repositorio público de instalación para ISLA de Datos Urbanos 2025-2026.

Este repositorio NO contiene el código fuente principal de la plataforma.  
Solo incluye:

- instaladores multiplataforma
- Docker Compose
- plantillas de configuración
- scripts mínimos de inicialización
- integración con imágenes Docker publicadas en GHCR

El backend, frontend, pipelines y lógica experimental permanecen en un repositorio privado.

---

# Instalación

## Linux / WSL2 / macOS

Ejecutar:

```bash
curl -fsSL https://raw.githubusercontent.com/ROKOPM/isla-installer/main/setup.sh | bash
```

---

## Windows PowerShell

Requisitos:

- Windows 10/11
- Docker Desktop
- Docker Compose v2
- PowerShell

Ejecutar:

```powershell
irm https://raw.githubusercontent.com/ROKOPM/isla-installer/main/setup.ps1 | iex
```

También puede ejecutarse desde CMD:

```cmd
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/ROKOPM/isla-installer/main/setup.ps1 | iex"
```

---

# GHCR Privado

Si las imágenes GHCR están privadas, iniciar sesión antes de instalar:

```bash
echo TU_TOKEN | docker login ghcr.io -u ROKOPM --password-stdin
```

El token necesita:

```text
read:packages
```

---

# Requisitos

- Docker
- Docker Compose v2
- Git
- Recomendado: GPU NVIDIA para Ollama
- Recomendado: 16 GB RAM mínimo
- Recomendado: 50 GB libres o más

---

# Imágenes Utilizadas

## Imágenes propias

```text
ghcr.io/rokopm/isla-webservice:latest
ghcr.io/rokopm/isla-django:latest
ghcr.io/rokopm/isla-qwen-worker:latest
ghcr.io/rokopm/isla-habits-worker:latest
ghcr.io/rokopm/isla-davis-poller:latest
ghcr.io/rokopm/isla-nginx:latest
```

## Imágenes externas

```text
pgvector/pgvector:pg16
ollama/ollama:latest
```

---

# Configuración

Durante la instalación se crea un `.env` local desde `.env.template`.

El instalador solicita:

- `DAVIS_API_KEY`
- `DAVIS_API_SECRET`
- `DAVIS_STATION_ID`

El archivo `.env` nunca debe subirse al repositorio.

---

# Operación

Abrir:

```text
http://localhost
```

Comandos útiles:

```bash
docker compose ps
docker compose logs -f nginx
docker compose logs -f django
docker compose logs -f habits_worker
docker compose up -d
docker compose down
```

---

# Validación

Linux/macOS/WSL:

```bash
bash -n setup.sh
docker compose config
docker compose pull
docker compose up -d
curl -I http://localhost
```

Windows PowerShell:

```powershell
docker compose config
docker compose pull
docker compose up -d
curl http://localhost
```

Resultado esperado:

```text
HTTP/1.1 200 OK
```

---

# Seguridad

Este repositorio NO contiene:

- código fuente Django
- código fuente frontend
- código fuente de workers
- prompts privados
- ETL privado
- embeddings privados
- `.env`
- tokens
- API keys reales
- backups
- dumps SQL sensibles
- datasets
- modelos Ollama

---


# Proyecto

ISLA de Datos Urbanos 2025-2026 es una plataforma de análisis urbano basada en:

- visión computacional
- modelos multimodales
- clustering conductual
- embeddings semánticos
- monitoreo ambiental
- analítica temporal
- minería de datos urbanos
