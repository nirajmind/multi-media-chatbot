ifeq (,$(wildcard .env))
$(error .env file is missing. Please create one based on .env.example)
endif

include .env

CHECK_DIRS := .

# Define service-to-Dockerfile mapping and image names
HF_DOWNLOADER_DOCKERFILE = Dockerfile.hf_models
HF_DOWNLOADER_IMAGE_TAG = $(COMPOSE_PROJECT_NAME)_hf_models_downloader:latest

WHATSAPP_DOCKERFILE = Dockerfile.whatsapp
WHATSAPP_IMAGE_TAG = $(COMPOSE_PROJECT_NAME)_whatsapp:latest

CHAINLIT_DOCKERFILE = Dockerfile.chainlit
CHAINLIT_IMAGE_TAG = $(COMPOSE_PROJECT_NAME)_chainlit:latest

EMBEDDING_DOCKERFILE = Dockerfile.embedding_service
EMBEDDING_IMAGE_TAG = $(COMPOSE_PROJECT_NAME)_embedding_service:latest

# Set COMPOSE_PROJECT_NAME if it's not inherited
COMPOSE_PROJECT_NAME ?= ava-whatsapp-agent-course

ava-build:
	docker compose build

ava-run:
	docker compose up --build -d

ava-stop:
	docker compose stop

ava-delete:
	@if [ -d "long_term_memory" ]; then rm -rf long_term_memory; fi
	@if [ -d "short_term_memory" ]; then rm -rf short_term_memory; fi
	@if [ -d "generated_images" ]; then rm -rf generated_images; fi
	docker compose down

format-fix:
	uv run ruff format $(CHECK_DIRS) 
	uv run ruff check --select I --fix $(CHECK_DIRS)

lint-fix:
	uv run ruff check --fix $(CHECK_DIRS)

format-check:
	uv run ruff format --check $(CHECK_DIRS) 
	uv run ruff check -e $(CHECK_DIRS)
	uv run ruff check --select I -e $(CHECK_DIRS)

lint-check:
	uv run ruff check $(CHECK_DIRS)