PLATFORM := $(shell uname)

DC=docker-compose
DB_NAME=app
APP=$(DC) exec -u 1000 app
DB = $(DC) exec db
DBT = $(DC) exec -T db
DCRUN_NODE=${DC} run --rm -u 1000 node

default:
	@echo 'Please provide correct command'

up: down
	$(DC) up -d --build

down:
	$(DC) down

bash:
	$(APP) /bin/bash

db:
	$(DB) /bin/bash

import-database:
	$(DB) mysql -uroot -proot -e "drop database if exists $(DB_NAME);"
	$(DB) mysql -uroot -proot -e "create database $(DB_NAME);"
	gunzip -c ./docker/dumps/$(DB_NAME).sql.gz | ${DBT} mysql -uroot -proot -D ${DB_NAME}

dump-database:
	$(DBT) mysqldump -uroot -proot $(DB_NAME) > dump.sql

composer:
	${APP} composer install
	$(APP) composer install --working-dir=tools/php-cs-fixer

assets-install:
	${DCRUN_NODE} yarn install

assets-bash:
	${DCRUN_NODE} bash

assets-dev:
	${DCRUN_NODE} yarn run dev

assets-prod:
	${DCRUN_NODE} yarn run production

assets-watch:
	${DCRUN_NODE} yarn run watch

cs-fix-dry:
	$(APP) php tools/php-cs-fixer/vendor/bin/php-cs-fixer fix --diff --config=tools/php-cs-fixer/.php_cs.dist.php --dry-run -vvv

cs-fix:
	$(APP) php tools/php-cs-fixer/vendor/bin/php-cs-fixer fix --diff --config=tools/php-cs-fixer/.php_cs.dist.php -vvv

ide-helper:
	$(APP) php artisan clear-compiled
	$(APP) php artisan ide-helper:generate
	$(APP) php artisan ide-helper:models --nowrite
	$(APP) php artisan ide-helper:meta

setup-phpunit:
	$(DB) mysql -u root -proot -e "DROP DATABASE IF EXISTS test"
	$(DB) mysql -u root -proot -e "CREATE DATABASE test"
	$(APP) php artisan config:clear
	$(APP) php artisan cache:clear
	$(APP) php artisan migrate --env=testing -vvv
	$(APP) php artisan db:seed --class=TestingDatabaseSeeder --env=testing -vvv

run-tests:
	$(APP) php artisan optimize:clear
	$(APP) php artisan test
