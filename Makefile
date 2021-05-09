all: build up ps
reset: downv prune build up ps

prune:
	docker system prune -f
ps:
	docker-compose ps
up:
	docker-compose up -d
build:
	COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker-compose build
downv:
	docker-compose down -v
login:
	docker-compose exec nginx bash
