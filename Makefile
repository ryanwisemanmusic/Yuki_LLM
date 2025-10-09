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

.PHONY: run-setup-app run-webui stop-webui

# Configuration
MODEL_NAME := deepseek-coder:33b
CUSTOM_MODEL_NAME := yuki-llm
MODFILE := ./Modfile

# Fast WebUI setup - assumes models are already created via your existing workflow
.PHONY: clean-run-setup-app run-setup-app run-webui-with-model

clean-run-setup-app: 
	@echo "==CLEANING PREVIOUS RUN DATA=="
	@docker-compose down 2>/dev/null || true
	@rm -f /tmp/yuki-pull-response.json
	@rm -f /tmp/yuki-create-response.json
	@rm -rf .vscode/payload.json
	@echo "Starting fresh run-setup-app..."
	@$(MAKE) run-setup-app

run-setup-app:
	@echo "==STARTING SERVICES WITH INDEFINITE KEEP-ALIVE=="
	docker-compose down 2>/dev/null || true
	docker-compose up -d
	@echo "Waiting for services to start..."
	sleep 15

	# PULL THE BASE MODEL FIRST
	@echo "Pulling base model $(MODEL_NAME)..."
	@curl -s -X POST http://localhost:11434/api/pull \
		-H "Content-Type: application/json" \
		--data-raw '{"name":"'"$(MODEL_NAME)"'"}' | tee /tmp/yuki-pull-response.json

	./build-modfile.sh
	
	@echo "Creating yuki-llm model from Modfile..."
	@# Use the exact same approach that works in 'make run'
	@-ollama rm yuki-llm 2>/dev/null || true
	@ollama create yuki-llm -f ./Modfile
	@echo "Yuki-LLM model created successfully using CLI"

	@echo "Loading models into active serving state..."
	@# Load both models to trigger active serving state
	@curl -s -X POST http://localhost:11434/api/generate \
		-H "Content-Type: application/json" \
		-d '{"model": "yuki-llm", "prompt": "ping", "stream": false}' > /dev/null 2>&1 && echo "Yuki-LLM actively serving" || echo "Yuki-LLM load completed"
	@curl -s -X POST http://localhost:11434/api/generate \
		-H "Content-Type: application/json" \
		-d '{"model": "phi", "prompt": "ping", "stream": false}' > /dev/null 2>&1 && echo "Phi actively serving" || echo "Phi load completed"

	@echo "Open WebUI: http://localhost:3001"
	@echo "Both yuki-llm and phi are actively serving and will stay loaded indefinitely"
	@echo "Thanks to OLLAMA_KEEP_ALIVE=-1 in docker-compose.yml"

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
	-pkill -f "curl.*api/chat" 2>/dev/null || true
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