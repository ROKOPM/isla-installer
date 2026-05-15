# ISLA de Datos Urbanos Installer

Repositorio publico de instalacion para ISLA de Datos Urbanos 2025-2026.

Este repo no contiene el codigo fuente de la plataforma. Solo incluye el instalador, Docker Compose, plantilla de variables y scripts SQL de inicializacion de base de datos necesarios para levantar el sistema desde imagenes Docker publicadas en GHCR.

## Instalacion

```bash
curl -fsSL https://raw.githubusercontent.com/ROKOPM/isla-installer/main/setup.sh | bash
```

Si las imagenes GHCR estan privadas, primero inicia sesion:

```bash
echo TU_TOKEN | docker login ghcr.io -u ROKOPM --password-stdin
```

El token necesita `read:packages`.

## Requisitos

- Docker
- Docker Compose v2
- Git
- Runtime NVIDIA para Docker si se usara Ollama con GPU
- Recomendado: 16 GB RAM minimo
- Recomendado: 50 GB libres o mas

## Imagenes Usadas

Imagenes propias:

```text
ghcr.io/rokopm/isla-webservice:latest
ghcr.io/rokopm/isla-django:latest
ghcr.io/rokopm/isla-qwen-worker:latest
ghcr.io/rokopm/isla-habits-worker:latest
ghcr.io/rokopm/isla-davis-poller:latest
ghcr.io/rokopm/isla-nginx:latest
```

Imagenes externas:

```text
pgvector/pgvector:pg16
ollama/ollama:latest
```

## Configuracion

Durante la instalacion se crea un `.env` local desde `.env.template`.

El instalador solicita:

- `DAVIS_API_KEY`
- `DAVIS_API_SECRET`
- `DAVIS_STATION_ID`

El archivo `.env` nunca debe subirse al repositorio.

## Operacion

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

## Validacion

```bash
bash -n setup.sh
docker compose config
docker compose pull
docker compose up -d
curl -I http://localhost
```

Resultado esperado:

```text
HTTP/1.1 200 OK
```

## Seguridad

No contiene:

- codigo fuente de Django
- codigo fuente de workers
- codigo fuente de frontend
- prompts privados
- ETL privado
- `.env`
- tokens
- Davis API keys reales
- backups
- dumps de base de datos

Nota: las imagenes Docker publicas pueden ser inspeccionadas por usuarios avanzados. Para ocultar propiedad intelectual de forma fuerte no basta con hacer privado el repositorio fuente; tambien habria que endurecer el empaquetado de las imagenes.
