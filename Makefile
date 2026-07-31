# Gravity Brewing website — local development.
#
# Netlify bills per production deploy, so nothing here needs Netlify: the site
# builds and serves entirely locally. Hugo is pinned to the SAME version
# Netlify uses by reading it out of netlify.toml, so the two cannot drift
# without the drift being visible here.

HUGO_VERSION := $(shell sed -n 's/.*HUGO_VERSION = "\(.*\)".*/\1/p' netlify.toml)
HUGO_DIR     := .bin
HUGO         := $(HUGO_DIR)/hugo
HUGO_TARBALL := hugo_extended_$(HUGO_VERSION)_linux-amd64.tar.gz
HUGO_URL     := https://github.com/gohugoio/hugo/releases/download/v$(HUGO_VERSION)/$(HUGO_TARBALL)

# .env holds KIT_EVENTS_URL and KIT_EVENTS_TOKEN for the live-feed targets.
# Optional: the default `make dev` deliberately runs without it.
-include .env
export

.DEFAULT_GOAL := help

$(HUGO):
	@echo "Fetching Hugo $(HUGO_VERSION) (extended)..."
	@mkdir -p $(HUGO_DIR)
	@curl -sSfL $(HUGO_URL) -o $(HUGO_DIR)/hugo.tar.gz
	@tar xzf $(HUGO_DIR)/hugo.tar.gz -C $(HUGO_DIR) hugo
	@rm -f $(HUGO_DIR)/hugo.tar.gz
	@$(HUGO) version

.PHONY: setup
setup: $(HUGO) ## Install the pinned Hugo into .bin/

.PHONY: dev
dev: $(HUGO) ## Serve locally with SAMPLE events (no network, no Kit needed)
	@echo "Sample events — nothing on this page is real. Use 'make dev-live' for Kit data."
	@env -u KIT_EVENTS_URL -u KIT_EVENTS_TOKEN $(HUGO) server --buildDrafts --disableFastRender

.PHONY: dev-live
dev-live: $(HUGO) require-feed ## Serve locally against the real Kit events feed
	@$(HUGO) server --disableFastRender

.PHONY: build
build: $(HUGO) require-feed ## Production build, exactly as Netlify runs it
	@HUGO_ENV=production $(HUGO) --gc --minify --cleanDestinationDir

.PHONY: build-sample
build-sample: $(HUGO) ## Production-flag build against sample data (should FAIL — proves the guard)
	@env -u KIT_EVENTS_URL -u KIT_EVENTS_TOKEN HUGO_ENV=production $(HUGO) --gc --minify --cleanDestinationDir

.PHONY: feed
feed: require-feed ## Print the live feed Kit is serving
	@curl -sS -H "Authorization: Bearer $(KIT_EVENTS_TOKEN)" "$(KIT_EVENTS_URL)"

.PHONY: snapshot
snapshot: require-feed ## Save the live feed as the committed last-good fallback
	@curl -sSf -H "Authorization: Bearer $(KIT_EVENTS_TOKEN)" "$(KIT_EVENTS_URL)" > data/events.json
	@echo "Wrote data/events.json ($$(wc -c < data/events.json) bytes)"

.PHONY: require-feed
require-feed:
	@test -n "$(KIT_EVENTS_URL)"   || { echo "KIT_EVENTS_URL is not set. Copy .env.example to .env and fill it in."; exit 1; }
	@test -n "$(KIT_EVENTS_TOKEN)" || { echo "KIT_EVENTS_TOKEN is not set. Copy .env.example to .env and fill it in."; exit 1; }

.PHONY: clean
clean: ## Remove build output and caches
	@rm -rf public resources .hugo_build.lock
	@rm -rf $$($(HUGO) config 2>/dev/null | sed -n "s/^cachedir = '\(.*\)'/\1/p")/getresource

.PHONY: help
help:
	@grep -hE '^[a-z-]+:.*##' $(MAKEFILE_LIST) | sort | awk 'BEGIN{FS=":.*##"}{printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'
