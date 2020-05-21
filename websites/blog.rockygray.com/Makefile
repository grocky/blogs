GREEN  := $(shell tput -Txterm setaf 2)
NC     := $(shell tput -Txterm sgr0)

MARKDOWN = pandoc --from gfm --to html --standalone

SOURCES := $(shell find . -not \( -path ./.git -prune \) -name "*.md")

SITE_BUCKET := blog.rockygray.com
BUILD_DIR := build

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

clean: phony ## cleanup
	-rm -r ${BUILD_DIR} 2>/dev/null || true

serve: phony ## serve content with watcher
	hugo server -D

update-theme: phony ## update themes
	git submodule update --rebase --remote

build: $(SOURCES) ## build the site
	hugo -v -d ${BUILD_DIR} --minify

deploy: build ## deploy the site
	aws s3 sync --cache-control 'max-age=604800' --exclude index.html build/ s3://$(SITE_BUCKET)
	aws s3 sync --cache-control 'no-cache' build/ s3://$(SITE_BUCKET)

### Infrastructure ###

tf-plan: phony ## terraform plan
	cd infrastructure; terraform plan

tf-init: phony ## initialize terraform when adding new integrations
	cd infrastructure; terraform init

tf-apply: phony ## apply infrastructure
	cd infrastructure; terraform apply -auto-approve
