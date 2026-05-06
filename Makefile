all: format check test build run package

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

# this target requires FreeBSD to run
.PHONY:package
package:
	rm -rf ./tmp
	sudo service example stop
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

.PHONY:foo
foo:
	echo "CURDIR=$(CURDIR)"
	echo "PWD=$(PWD)"
