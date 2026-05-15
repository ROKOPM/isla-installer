.PHONY: config pull up down ps logs logs-nginx logs-django logs-habits validate

config:
	docker compose config

pull:
	docker compose pull

up:
	docker compose up -d

down:
	docker compose down

ps:
	docker compose ps

logs:
	docker compose logs -f

logs-nginx:
	docker compose logs -f nginx

logs-django:
	docker compose logs -f django

logs-habits:
	docker compose logs -f habits_worker

validate:
	bash -n setup.sh
	docker compose config
