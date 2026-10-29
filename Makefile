APP_NAME := Mikelito
APP      := build/$(APP_NAME).app
BIN_NAME := Mikelito
INSTALL_DIR ?= $(HOME)/Applications

.PHONY: help check build debug app universal run install uninstall quit logs crash-report clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-14s %s\n", $$1, $$2}'

check: ## Check that this Mac can build the app
	scripts/check_env.sh

build: ## Compile the release binary
	swift build -c release

debug: ## Compile the debug binary
	swift build

app: ## Build the signed .app bundle for this Mac into ./build
	scripts/build_app.sh

universal: ## Build a universal (Apple Silicon + Intel) .app into ./build
	UNIVERSAL=1 scripts/build_app.sh

run: quit app ## Rebuild, stop any running copy, and launch the app
	open "$(APP)"

install: app ## Copy the app to INSTALL_DIR (default ~/Applications, no admin needed)
	mkdir -p "$(INSTALL_DIR)"
	rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"
	cp -R "$(APP)" "$(INSTALL_DIR)/"

uninstall: quit ## Remove the app from INSTALL_DIR
	rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"

quit: ## Stop any running copy
	-@pkill -f "$(APP_NAME).app/Contents/MacOS/$(BIN_NAME)"; true

logs: ## Stream the app's log output
	log stream --style compact --predicate 'process == "$(APP_NAME)"'

crash-report: ## Print the latest crash report's exception and stack
	@f=$$(ls -t ~/Library/Logs/DiagnosticReports/$(APP_NAME)-*.ips 2>/dev/null | head -1); \
	if [ -z "$$f" ]; then echo "No crash reports found."; exit 0; fi; \
	echo "$$f"; \
	python3 -c 'import json,sys; r=json.loads(open(sys.argv[1]).read().split("\n",1)[1]); print(r.get("exception"), r.get("asi")); t=[x for x in r["threads"] if x.get("triggered")][0]; [print(r["usedImages"][f["imageIndex"]].get("name"), f.get("symbol")) for f in t["frames"][:15]]' "$$f"

clean: ## Remove build artifacts
	swift package clean
	rm -rf .build build
