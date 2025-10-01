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
	ollama run yuki-llm "Write a Dockerfile, barebones, using Alpine Linux, that can be ran" | tee $(TEST_LOG)