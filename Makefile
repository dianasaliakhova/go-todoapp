include .env
export 

# shell pwd-print working directory
export PROJECT_ROOT=$(shell pwd)

env-up:
	@docker compose up -d todoapp-postgres
# 	--d - запуск в фоновом режиме, не блокируясь терминальной сессией

env-down:
	@docker compose down todoapp-postgres

# очистка окружения, предусматриваем механиизмы случайного вызова=>подтерждение
env-cleanup:
	@read -p "Очистить все volume файлы окружения? Опасность потери данных. [y/N]: " ans; \
	if [ "$$ans" = "y" ]; then \
		@docker compose down todoapp-postgres && \
		rm -rf out/pgdata && \
		echo "Файлы окружения очищены"; \
	else \
		echo "Очистка отменена"; \
	fi

migrate-create:
# проверяем задана ли переменная seq, если нет - выводим сообщение и завершаем выполнение
	@if [ -z "$(seq)" ]; then \
		echo "Ошибка: переменная seq не задана. Использование: make migrate-create seq=название_миграции"; \
		exit 1; \
	fi
# up - долгоживущие сервисы, run - отработать 1 раз и завершиться
# --rm - как только контейнер остановится сразу удали установл контейнер
# через create создаем новый файл миграции
	@docker compose run --rm todoapp-postgres-migrate \
		create \
		-ext sql \
		-dir /migrations \
		-seq "$(seq)"

# передаем путь до файлов миграции внутри докер контейнера, path.
# После, передаем строку подключения к постгресу нах внутри сервиса todoapp-postgres
# Подставляем переменные из окружения в database
# postgres-протокол подключения
# после @ передаем хост на котором с точки зрения запускаемого сервера расположена БД postgresql
# тк в одном компоузе докер автоматом создаст компоуз сеть в котором будут находится все сервисы. изолированная сеть
# доступ с хост системы надо настроить. но они друг к другу могут обращаться, в качестве хоста - название сервиса
# sslmode - чтобы либа migrate без доп настройки могла получать доступ к БД

migrate-action: 
	@if [ -z "$(action)" ]; then \
		echo "Ошибка: переменная action не задана. Использование: make migrate-action action=up"; \
		exit 1; \
	fi
	@docker compose run --rm todoapp-postgres-migrate \
		-path /migrations \
		-database postgres://$(POSTGRES_USER):$(POSTGRES_PASSWORD)@todoapp-postgres:5432/$(POSTGRES_DB)?sslmode=disable \
		"$(action)"

migrate-up:
	@make migrate-action action=up

migrate-down:
	@make migrate-action action=down


env-port-forward:
	@docker compose up -d port-forwarder

env-port-close:
	@docker compose down port-forwarder