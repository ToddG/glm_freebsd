all: format check test build run

INSTALL_DIR := /usr/local/bin

.PHONY:path
path:
	echo "PATH=${PATH}"

.PHONY:clean
clean:
	gleam clean

.PHONY:format
format:
	gleam format

.PHONY:check
check:
	gleam check

.PHONY:test
test:
	gleam "test"

.PHONY:build
build:
	gleam build --target erlang

.PHONY:run
run:
	gleam run -- --help

.PHONY:freebsd_package
freebsd_package:
	echo "this target requires FreeBSD to run"
	rm -rf ./tmp
	sudo service example stop || true
	cd ./priv/example; gleam export erlang-shipment
	gleam run -- -a $(PWD)/priv/example -s $(PWD)/tmp/staging -t $(PWD)/priv/example/priv/custom/templates -o $(PWD)/tmp/output
	sudo pkg install -y $(PWD)/tmp/output/example-1.0.0.pkg
	sudo service example start
	sudo service example status
	sudo cat /var/log/example.log
	sudo service example stop
	sudo pkg remove -y example

.PHONY:birdie
birdie:
	gleam run -m birdie

.PHONY:install
install:
	sudo gleam run -m gleescript -- --out=$(INSTALL_DIR)
