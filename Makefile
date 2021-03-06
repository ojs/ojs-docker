PROJECT := OJS

default: build

build: nginx
	@docker-compose -f docker-compose.development.yaml --project ojs up -d postgres

	@docker build \
			--build-arg GITHUB_TOKEN=${GITHUB_TOKEN} \
			-f ojs/Dockerfile -t ojs:fpm .

nginx:
	@docker build -f nginx/Dockerfile -t  ojs:nginx .

development:
	@docker-compose -f docker-compose.$@.yaml --project-name $(PROJECT) up

production:
	@docker-compose -f docker-compose.$@.yaml --project-name $(PROJECT) up -d

down:
	@docker-compose -f docker-compose.development.yaml --project-name $(PROJECT) down

workarounds:
	@sysctl -w vm.max_map_count=262144

builder:
	$(MAKE) -C $@

ojs/master.zip:
	@curl -L https://github.com/ojs/ojs/archive/master.zip > $@

unzip: ojs/master.zip
	@unzip -o $< && rsync -avh --update -e  ojs-master app

prebuild: builder unzip
	@docker run --rm -it \
		--volume $(CURDIR)/app:/app ojs:builder install

test: build
	@docker run -it ojs pwd # sh -li

.PHONY: default build development down production workarounds prebuild builder unzip nginx