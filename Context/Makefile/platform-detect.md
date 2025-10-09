Please utilize this approach when attempting to detect platforms.

## PROVEN APPROACH FOR PLATFORM DETECTION FOR MAC PLATFORMS (UNVERIFIED FOR WINDOWS AND LINUX):
I recommend here that if you need platform detection in the Makefile, 

## CODE EXAMPLE FOR REFERENCE:
As a note: If you generate an alternative to this code and the user says,
this does not work; you MUST use this code
Now that you understand, here is a relevant block of code that you should use, albeit, with the name 'detect-build-method' changed to something related to platform detection:

UNAME_S := $(shell uname -s)
HAS_BREW := $(shell command -v brew >/dev/null 2>&1 && echo yes || echo no)
HAS_CMAKE := $(shell command -v cmake >/dev/null 2>&1 && echo yes || echo no)
PROJECT_ROOT := $(shell pwd)

detect-build-method:
	@echo "=== Build Method Detection ==="
	@echo "OS: $(UNAME_S)"
	@echo "Homebrew available: $(HAS_BREW)"
	@echo "CMake available: $(HAS_CMAKE)"
	@echo "Project root: $(PROJECT_ROOT)"
	@if [ "$(UNAME_S)" = "Darwin" ] && [ "$(HAS_BREW)" = "yes" ] && [ "$(HAS_CMAKE)" = "yes" ]; then \
		echo "Native macOS build available - using Cocoa!"; \
	else \
		echo "Using Docker build method"; \
		$(MAKE) build-docker && $(MAKE) run-docker; \
	fi
