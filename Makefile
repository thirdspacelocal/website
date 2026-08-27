# Gravity Brewing website — local development.
#
# Netlify bills per production deploy, so nothing here needs Netlify: the site
# builds and serves entirely locally. Hugo is pinned to the SAME version
# Netlify uses by reading it out of netlify.toml, so the two cannot drift
# without the drift being visible here.

HUGO_VERSION := $(shell sed -n 's/.*HUGO_VERSION = "\(.*\)".*/\1/p' netlify.toml)
HUGO_DIR     := .bin
HUGO         := $(HUGO_DIR)/hugo
# Netlify builds on linux-amd64; a developer machine may not be. Resolve the
# platform rather than hardcoding Netlify's, or `make setup` fetches a binary
# that cannot execute here and every target dies with "exec format error".
#
# The VERSION stays pinned to netlify.toml regardless: matching Netlify's Hugo
# is the point, matching its CPU is not.
#
# The two platforms are packaged DIFFERENTLY by upstream -- Linux ships a
# tarball, macOS ships only a .pkg (there is no darwin tar.gz to fetch) -- so
# the download and the unpack both vary. Hence a per-platform archive name and
# a per-platform extract command rather than one rule with a substituted URL.
HUGO_UNAME_S := $(shell uname -s)
HUGO_UNAME_M := $(shell uname -m)

ifeq ($(HUGO_UNAME_S),Darwin)
  HUGO_PLATFORM := darwin-universal
  HUGO_ARCHIVE  := hugo_extended_$(HUGO_VERSION)_$(HUGO_PLATFORM).pkg
else
  ifeq ($(HUGO_UNAME_M),aarch64)
    HUGO_PLATFORM := linux-arm64
  else
    HUGO_PLATFORM := linux-amd64
  endif
  HUGO_ARCHIVE := hugo_extended_$(HUGO_VERSION)_$(HUGO_PLATFORM).tar.gz
endif

HUGO_URL := https://github.com/gohugoio/hugo/releases/download/v$(HUGO_VERSION)/$(HUGO_ARCHIVE)

# .env holds KIT_EVENTS_URL and KIT_EVENTS_TOKEN for the live-feed targets.
# Optional: the default `make dev` deliberately runs without it.
-include .env
export

.DEFAULT_GOAL := help

$(HUGO):
	@echo "Fetching Hugo $(HUGO_VERSION) (extended, $(HUGO_PLATFORM))..."
	@mkdir -p $(HUGO_DIR)
	@curl -sSfL $(HUGO_URL) -o $(HUGO_DIR)/$(HUGO_ARCHIVE)
ifeq ($(HUGO_UNAME_S),Darwin)
	@# The macOS build is only published as an installer package. Expanding it
	@# in place keeps the binary in .bin/ alongside the Linux one instead of
	@# installing Hugo system-wide, so the pinned version cannot leak out of
	@# this repo or collide with a Hugo the developer already has.
	@rm -rf $(HUGO_DIR)/pkg
	@pkgutil --expand-full $(HUGO_DIR)/$(HUGO_ARCHIVE) $(HUGO_DIR)/pkg
	@cp $(HUGO_DIR)/pkg/Payload/hugo $(HUGO)
	@chmod +x $(HUGO)
	@rm -rf $(HUGO_DIR)/pkg
else
	@tar xzf $(HUGO_DIR)/$(HUGO_ARCHIVE) -C $(HUGO_DIR) hugo
endif
	@rm -f $(HUGO_DIR)/$(HUGO_ARCHIVE)
	@$(HUGO) version

.PHONY: setup
setup: $(HUGO) ## Install the pinned Hugo into .bin/

.PHONY: dev
dev: $(HUGO) require-feed ## Serve locally against Kit's live feed
	@$(HUGO) server --buildDrafts --disableFastRender

.PHONY: build
build: $(HUGO) require-feed ## Production build, exactly as Netlify runs it
	@HUGO_ENV=production $(HUGO) --gc --minify --cleanDestinationDir

.PHONY: feed
feed: require-feed ## Print the live feed Kit is serving
	@curl -sS -H "Authorization: Bearer $(KIT_EVENTS_TOKEN)" "$(KIT_EVENTS_URL)"

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
