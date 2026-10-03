SHELL := /bin/bash
PROJECT_DIR := $(shell pwd)
COMPOSE_DIR := $(PROJECT_DIR)/compose
SCRIPTS_DIR := $(PROJECT_DIR)/scripts

include $(PROJECT_DIR)/.env
export

PROFILE ?= web

.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo "================================================================================"
	@echo "  PENTEST LAB - Comandos disponibles"
	@echo "================================================================================"
	@echo "  make setup            Configura red y directorios (primera vez)"
	@echo "  make build            Construye la imagen del atacante"
	@echo "  make up-recon         Levanta perfil recon (attacker)"
	@echo "  make up-web           Levanta perfil web (attacker + dvwa + juice-shop)"
	@echo "  make up-smb           Levanta perfil smb (attacker + metasploitable + samba)"
	@echo "  make up-full          Levanta todos los contenedores"
	@echo "  make down             Detiene todos los contenedores"
	@echo "  make status           Estado de los contenedores"
	@echo "  make shell            Conectar al atacante"
	@echo "  make logs             Ver logs del atacante"
	@echo "  make health           Health check (PROFILE=web|smb|full, default web)"
	@echo "  make reset            Reset completo"
	@echo "  make clean            Elimina imágenes locales"
	@echo "  make build            Construye la imagen del atacante (usa caché)"
	@echo "  make rebuild          Reconstruye la imagen sin caché"
	@echo "================================================================================"

.PHONY: setup
setup:
	@bash $(SCRIPTS_DIR)/setup.sh

.PHONY: build
build:
	@echo ">>> Construyendo imagen del atacante..."
	podman build -t localhost/wired:latest \
		-f containers/wired/Containerfile containers/wired/
	@echo ">>> Imagen construida"

.PHONY: up-recon
up-recon: setup
	@bash $(SCRIPTS_DIR)/up.sh recon

.PHONY: up-web
up-web: setup
	@bash $(SCRIPTS_DIR)/up.sh web

.PHONY: up-smb
up-smb: setup
	@bash $(SCRIPTS_DIR)/up.sh smb

.PHONY: up-full
up-full: setup
	@bash $(SCRIPTS_DIR)/up.sh full

.PHONY: down
down:
	@bash $(SCRIPTS_DIR)/down.sh

.PHONY: status
status:
	@bash $(SCRIPTS_DIR)/status.sh

.PHONY: shell
shell:
	@bash $(SCRIPTS_DIR)/connect.sh

.PHONY: logs
logs:
	@podman logs -f inici4rsesi0n_wired

.PHONY: health
health:
	@bash $(SCRIPTS_DIR)/healthcheck.sh $(PROFILE)

.PHONY: reset
reset:
	@bash $(SCRIPTS_DIR)/reset.sh

.PHONY: clean
clean:
	@podman rmi localhost/wired:latest 2>/dev/null || true
	@echo ">>> Imágenes eliminadas"

.PHONY: rebuild
rebuild:
	@echo ">>> Reconstruyendo imagen del atacante sin caché..."
	podman build --no-cache -t localhost/wired:latest \
		-f containers/wired/Containerfile containers/wired/
	@echo ">>> Imagen reconstruida"

.PHONY: smoke
smoke:
	@bash tests/smoke_test.sh
