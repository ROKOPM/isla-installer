# ISLA de Datos Urbanos Installer

Repositorio publico de instalacion del pipeline central de ISLA de Datos Urbanos 2025-2026.

Este repositorio NO contiene el codigo fuente principal de la plataforma. Solo incluye:

- instaladores multiplataforma
- Docker Compose
- plantillas de configuracion
- scripts minimos de inicializacion
- integracion con imagenes Docker publicadas en GHCR

Codigo fuente y explicacion del proyecto:

```text
https://github.com/ROKOPM/Isladedatos2025-2026
```

Si tambien necesitas capturar imagenes desde una camara USB o RTSP, instala el nodo edge:

```text
https://github.com/ROKOPM/isla-edge-installer
```

---

# Instalacion

## Linux / WSL2 / macOS

```bash
curl -fsSL https://raw.githubusercontent.com/ROKOPM/isla-installer/main/setup.sh | bash
```

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

Tambien puede ejecutarse desde CMD:

```cmd
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/ROKOPM/isla-installer/main/setup.ps1 | iex"
```

## Windows con WSL2 Ubuntu

```powershell
wsl --install -d Ubuntu
```

Abrir Ubuntu y ejecutar:

```bash
curl -fsSL https://raw.githubusercontent.com/ROKOPM/isla-installer/main/setup.sh | bash
```

Despues abre:

```text
http://localhost
```

---

# GHCR Privado

Si las imagenes GHCR estan privadas, iniciar sesion antes de instalar:

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
- Recomendado: 16 GB RAM minimo
- Recomendado: 50 GB libres o mas

---

# Imagenes Utilizadas

## Imagenes propias

```text
ghcr.io/rokopm/isla-webservice:latest
ghcr.io/rokopm/isla-django:latest
ghcr.io/rokopm/isla-qwen-worker:latest
ghcr.io/rokopm/isla-habits-worker:latest
ghcr.io/rokopm/isla-davis-poller:latest
ghcr.io/rokopm/isla-nginx:latest
```

## Imagenes externas

```text
pgvector/pgvector:pg16
ollama/ollama:latest
```

---

# Configuracion

Durante la instalacion se crea un `.env` local desde `.env.template`.

El instalador solicita:

- `DAVIS_API_KEY`
- `DAVIS_API_SECRET`
- `DAVIS_STATION_ID`

El archivo `.env` nunca debe subirse al repositorio.

---

# Operacion

Abrir:

```text
http://localhost
```

Comandos utiles:

```bash
docker compose ps
docker compose logs -f nginx
docker compose logs -f django
docker compose logs -f habits_worker
docker compose up -d
docker compose down
```

---

# Validacion

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

- codigo fuente Django
- codigo fuente frontend
- codigo fuente de workers
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

ISLA de Datos Urbanos 2025-2026 es una plataforma de analisis urbano basada en:

- vision computacional
- modelos multimodales
- clustering conductual
- embeddings semanticos
- monitoreo ambiental
- analitica temporal
- mineria de datos urbanos
