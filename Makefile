# Any make commands related to modfiles
.PHONY: modfile

modfile:
	@echo "==MODFILE CREATION FROM SHELL SCRIPTS=="
	> $(MODFILE)
	chmod +x build-modfile.sh
	./build-modfile.sh
	@echo "==CLEANED YUKI-LLM MODFILE=="
	-ollama rm yuki-llm
	@echo "==GENERATING YUKI-LLM MODFILE=="
	ollama create yuki-llm -f ./Modfile 
	@echo "==YUKI-LLM MODFILE GENERATED=="

# Any make commands that run the LLM model via Ollama
.PHONY: run run-docker clean-log test-docker 
MODFILE = ./Modfile
TEST_LOG = ./llm_test.log

run: modfile clean-log
	ollama run yuki-llm "Please introduce yourself and explain what you specialize in." | tee $(TEST_LOG)

run-docker:
	@echo "== BUILDING DOCKER IMAGE =="
	docker build -t yuki-app .
	@echo "== RUNNING DOCKER CONTAINER =="
	docker run -it --rm yuki-app

clean-log:
	@echo "==CLEANING LOG FILE=="
	-rm $(TEST_LOG)
	@echo "==LOG FILE CLEANED=="

test-docker: modfile
	@echo "Test Run"
	ollama run yuki-llm "Generate me the code needed for building JACK2 from source." | tee $(TEST_LOG)

PHONY: run-setup-app run-webui stop-webui

# Configuration
MODEL_NAME := deepseek-coder:33b
CUSTOM_MODEL_NAME := yuki-llm
MODFILE := ./Modfile

# Fast WebUI setup - assumes models are already created via your existing workflow
.PHONY: run-setup-app run-webui-with-model

run-setup-app:
	@echo "==STARTING SERVICES WITH CONTINUOUS KEEP-ALIVE=="
	docker-compose down 2>/dev/null || true
	docker-compose up -d
	@echo "Waiting for services to start..."
	sleep 15

	# PULL THE BASE MODEL FIRST (no jq)
	@echo "Pulling base model $(MODEL_NAME)..."
	@curl -s -X POST http://localhost:11434/api/pull \
		-H "Content-Type: application/json" \
		--data-raw '{"name":"'"$(MODEL_NAME)"'"}' | tee /tmp/yuki-pull-response.json

	./build-modfile.sh

	@echo "Creating yuki-llm model from .vscode/payload.json..."
	@if [ -f .vscode/payload.json ]; then \
		curl -s -X POST http://localhost:11434/api/create \
			-H "Content-Type: application/json" \
			--data-binary @.vscode/payload.json | tee /tmp/yuki-create-response.json; \
	else \
		echo "ERROR: .vscode/payload.json not found. Create it with Option B JSON and retry."; \
		exit 1; \
	fi

	@# Show a short helpful summary if there was an error
	@grep -q '"error"' /tmp/yuki-create-response.json >/dev/null 2>&1 && ( \
		echo "Create failed — see /tmp/yuki-create-response.json"; \
		echo "Payload file: .vscode/payload.json"; \
		false \
	) || echo "Create succeeded"

	@echo "Starting indefinite model keep-alive service..."
	@nohup sh -c 'while true; do \
		curl -s -X POST http://localhost:11434/api/generate \
			-d "{\"model\": \"yuki-llm\", \"prompt\": \".\", \"stream\": false}" > /dev/null 2>&1; \
		sleep 60; \
	done' >/dev/null 2>&1 &

	@echo "Open WebUI: http://localhost:3001"
	@echo "To stop keep-alive: pkill -f \"curl.*api/generate\""




# Just start WebUI (super fast - for when models are already loaded)
run-webui:
	@echo "==STARTING WEBUI ONLY=="
	docker-compose up -d webui
	@echo "Open WebUI available at: http://localhost:3001"

stop-webui:
	@echo "==STOPPING WEBUI=="
	docker-compose down

.PHONY: clean clean-all clean-docker clean-models clean-volumes clean-images reset

# Clean up everything and start fresh
clean-all: clean-docker clean-models clean-volumes clean-images
	@echo "COMPLETE CLEANUP DONE"

# Clean Docker containers and networks using basic docker commands only
clean-docker:
	@echo "CLEANING DOCKER CONTAINERS AND NETWORKS"
	@echo "Stopping all containers..."
	-docker ps -aq | xargs -I {} docker stop {} 2>/dev/null || true
	@echo "Removing all containers..."
	-docker ps -aq | xargs -I {} docker rm {} 2>/dev/null || true
	@echo "Removing specific project containers..."
	-docker ps -a --filter "name=yukillm" --format "{{.ID}}" | xargs -I {} docker rm -f {} 2>/dev/null || true
	@echo "Cleaning networks..."
	-docker network prune -f

# Clean Ollama models
clean-models:
	@echo "CLEANING OLLAMA MODELS"
	-pkill -f "curl.*api/generate" 2>/dev/null || true
	-curl -s -X DELETE http://localhost:11434/api/delete -d '{"name": "yuki-llm"}' > /dev/null 2>&1 || true
	-curl -s -X DELETE http://localhost:11434/api/delete -d '{"name": "phi"}' > /dev/null 2>&1 || true
	-rm -f $(TEST_LOG) .keep-alive.pid

# Clean Docker volumes
clean-volumes:
	@echo "CLEANING DOCKER VOLUMES"
	-docker volume rm -f yukillm_ollama-data yukillm_webui-data 2>/dev/null || true
	-docker volume ls -q | xargs -I {} docker volume rm -f {} 2>/dev/null || true
	-docker volume prune -f

# Clean Docker images
clean-images:
	@echo "CLEANING DOCKER IMAGES"
	-docker rmi -f ollama/ollama ghcr.io/open-webui/open-webui:main 2>/dev/null || true
	-docker images -q | xargs -I {} docker rmi -f {} 2>/dev/null || true
	-docker image prune -f

# Reset everything and start fresh
reset: clean-all
	@echo "STARTING FRESH SETUP"
	@make run-setup-app

# Quick cleanup (containers only)
clean: clean-docker
	@echo "QUICK CLEANUP DONE"

# Nuclear option - restart Docker Desktop
nuclear:
	@echo "NUCLEAR OPTION - RESTARTING DOCKER DESKTOP"
	@echo "This will completely restart Docker. Continue? (y/N)" && read ans && [ $${ans:-N} = y ]
	-killall Docker 2>/dev/null || true
	-open -a Docker
	@sleep 10
	@echo "Docker restarted. Run 'make clean-all' again if needed."