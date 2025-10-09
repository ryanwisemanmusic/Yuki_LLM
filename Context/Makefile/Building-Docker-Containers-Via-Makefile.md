## GENERAL DOCKER BUILDING PROCEDURE:
There are three commands we want in our Makefile for running the Dockerfile:
- make clean-docker
- make build-docker 
- make run-docker

## DOCKER CLEAN STRUCTURE:
Keep in mind, the folders and app name will differ. You may change these labels ONLY (avoid touching anything else):
- sdl3-opengl-app
- sdl3-opengl-app-headless
- mostsignificant/simplehttpserver
- sdl3-base:latest 
- sdl3-debug:latest

I HIGHLY recommend using this EXACT structure for the make clean-docker command. It has been verified to work, and attempting to drift from this will create problems:

clean-docker:
	@echo "Cleaning up Docker resources..."
	@docker container rm -f sdl3-opengl-app sdl3-opengl-app-headless 2>/dev/null || true
	@docker image rm -f mostsignificant/simplehttpserver sdl3-base:latest sdl3-debug:latest 2>/dev/null || true
	@docker system prune -f >/dev/null 2>&1 || true
	@echo "Docker cleanup completed."

## DOCKER BUILD STRUCTURE:
Keep in mind, the folders and app name will differ. You may change these labels ONLY (please change these labels in both approaches, listed below):
- sdl3-base:latest
- sdl3-debug:latest
- mostsignificant/simplehttpserver

- To do a Docker build there are two approaches. The first is a more modular approach:
build-docker: build-base build-debug build-app

build-base:
	@echo "Building base Alpine image..."
	@docker build --platform=linux/arm64 --target base-deps -t sdl3-base:latest .

build-debug:
	@echo "Building debug image..."
	@docker build --platform=linux/arm64 --target debug -t sdl3-debug:latest .

build-app:
	@echo "Building main application image..."
	@docker build --platform=linux/arm64 --target runtime -t mostsignificant/simplehttpserver .

- This one isn't modular, but it is contained within a single command:
build-docker:
    @echo "Building base Alpine image..."
	@docker build --platform=linux/arm64 --target base-deps -t sdl3-base:latest .
	@echo "Building debug image..."
	@docker build --platform=linux/arm64 --target debug -t sdl3-debug:latest .
	@echo "Building main application image..."
	@docker build --platform=linux/arm64 --target runtime -t mostsignificant/simplehttpserver .