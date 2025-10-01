.PHONY: modfile

modfile:
	@echo "==CLEANED YUKI-LLM MODFILE=="
	-ollama rm yuki-llm
	@echo "==GENERATING YUKI-LLM MODFILE=="
	ollama create yuki-llm -f ./Modfile 
	@echo "==YUKI-LLM MODFILE GENERATED=="