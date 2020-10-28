GREEN  := $(shell tput -Txterm setaf 2)
NC     := $(shell tput -Txterm sgr0)

MARKDOWN = pandoc --from gfm --to html --standalone

SOURCES := $(shell find . -not \( -path ./.git -prune \) -name "*.md")

SITE_BUCKET := blog.rockygray.com
PREVIEW_SITE_BUCKET := preview-blog.rockygray.com
BUILD_DIR := build

.PHONY: phony
.DEFAULT_GOAL := help
##### Targets ######

help: phony ## print this help message
	@awk -F ':|##' '/^[^\t].+?:.*?##/ { printf "${GREEN}%-20s${NC}%s\n", $$1, $$NF }' $(MAKEFILE_LIST) | \
        sort

new-post: ## create a new post. Example: make new-post name=My-Awesome-Post
	hugo new --kind post posts/$(name)

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

.PHONY: build
build: $(SOURCES) ## build the site
	hugo -v -d ${BUILD_DIR} --minify

.PHONY: build-preview
build-preview: $(SOURCES) ## build the preview site
	hugo -v -d ${BUILD_DIR} --minify --buildDrafts --buildFuture --baseURL="https://$(PREVIEW_SITE_BUCKET)/"

deploy: build ## deploy the site
	aws s3 sync --cache-control 'max-age=604800,public' --exclude index.html $(BUILD_DIR)/ s3://$(SITE_BUCKET) --delete --size-only
	aws s3 cp --cache-control 'no-cache' $(BUILD_DIR)/index.html s3://$(SITE_BUCKET)/index.html

deploy-preview: ## deploy the preview site
	aws s3 sync --cache-control 'max-age=604800,public' --exclude index.html $(BUILD_DIR)/ s3://$(PREVIEW_SITE_BUCKET) --delete --size-only
	aws s3 cp --cache-control 'no-cache' $(BUILD_DIR)/index.html s3://$(PREVIEW_SITE_BUCKET)/index.html

### Infrastructure ###

tf-plan: phony ## terraform plan
	cd infrastructure; terraform plan

tf-init: phony ## initialize terraform when adding new integrations
	cd infrastructure; terraform init

tf-apply: phony ## apply infrastructure
	cd infrastructure; terraform apply -auto-approve
