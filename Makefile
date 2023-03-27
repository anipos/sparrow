.RUN_CONTEXT = docker compose exec ruby

up:
	docker compose up -d

down:
	docker compose down --remove-orphans

restart: down up logs

logs:
	docker compose logs -f

build:
	docker compose build

bash:
	$(.RUN_CONTEXT) bash

pre-push: rubocop test

test:
	$(.RUN_CONTEXT) rspec

rubocop:
	$(.RUN_CONTEXT) rubocop --auto-correct

yardoc:
	$(.RUN_CONTEXT) yardoc 'lib/**/*.rb'

bundle/install:
	$(.RUN_CONTEXT) bundle install
