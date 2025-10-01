# Any make commands related to modfiles
.PHONY: modfile

modfile:
	@echo "==CLEANED YUKI-LLM MODFILE=="
	-ollama rm yuki-llm
	@echo "==GENERATING YUKI-LLM MODFILE=="
	ollama create yuki-llm -f ./Modfile 
	@echo "==YUKI-LLM MODFILE GENERATED=="

# Any make commands that run the LLM model via Ollama
.PHONY: run clean-log test-docker
MODFILE = ./Modfile
TEST_LOG = ./llm_test.log

run: modfile clean-log
	ollama run yuki-llm $(MODFILE) | tee $(TEST_LOG)

clean-log:
	@echo "==CLEANING LOG FILE=="
	-rm $(TEST_LOG)
	@echo "==LOG FILE CLEANED=="

test-docker: modfile
	@echo "Test Run"
	ollama run yuki-llm "Write a Dockerfile, barebones, using Alpine Linux." | tee $(TEST_LOG)