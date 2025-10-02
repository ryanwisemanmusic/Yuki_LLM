Please utilize this approach when attempting to detect platforms.

## PROVEN APPROACH FOR PLATFORM DETECTION FOR ARM64 PLATFORMS:
detect-build-method:
	@echo "=== Build Method Detection ==="
	@echo "OS: $(UNAME_S)"
	@echo "Homebrew available: $(HAS_BREW)"
	@echo "CMake available: $(HAS_CMAKE)"
	@echo "Project root: $(PROJECT_ROOT)"
	@if [ "$(UNAME_S)" = "Darwin" ] && [ "$(HAS_BREW)" = "yes" ] && [ "$(HAS_CMAKE)" = "yes" ]; then \
		echo "✓ Native macOS build available - using Cocoa!"; \
	else \
		echo "→ Using Docker build method"; \
		$(MAKE) build-docker && $(MAKE) run-docker; \
	fi