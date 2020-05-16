GREEN  := $(shell tput -Txterm setaf 2)
NC     := $(shell tput -Txterm sgr0)

MARKDOWN = pandoc --from gfm --to html --standalone

SOURCES := $(shell find . -not \( -path ./.git -prune \) -name README.md)

.PHONY: phony
.DEFAULT_GOAL := help
##### Targets ######

help: phony ## print this help message
	@awk -F ':|##' '/^[^\t].+?:.*?##/ { printf "${GREEN}%-20s${NC}%s\n", $$1, $$NF }' $(MAKEFILE_LIST) | \
        sort

%.html: %.md
	    $(MARKDOWN) $< --output $@

init: ## Just setting things up...
	@echo $(SOURCES)
