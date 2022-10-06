# Copyright (c) 2020, David PHAM-VAN <dev.nfet.net@gmail.com>
# All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

FLUTTER?=$(realpath $(dir $(realpath $(dir $(shell which flutter)))))
FLUTTER_BIN=$(FLUTTER)/bin/flutter
DART_BIN=$(FLUTTER)/bin/dart
DART_SRC=$(shell find . -name '*.dart')

all: json_intl/example/.metadata format json_intl_gen/example/.metadata json_intl/pubspec.lock json_intl_gen/pubspec.lock

json_intl/example/.metadata:
	cd json_intl/example; flutter create -t app --no-overwrite --org net.nfet --project-name example .
	rm -rf json_intl/example/test json_intl/example/integration_test

json_intl_gen/example/.metadata:
	cd json_intl_gen/example; flutter create -t app --no-overwrite --org net.nfet --project-name example .
	rm -rf json_intl_gen/example/test json_intl_gen/example/integration_test

format: format-dart

format-dart: $(DART_SRC)
	$(DART_BIN) format --fix $^

clean:
	git clean -fdx -e .vscode

node_modules:
	npm install lcov-summary

json_intl/pubspec.lock: json_intl/pubspec.yaml
	cd json_intl; $(FLUTTER_BIN) pub get

json_intl_gen/pubspec.lock: json_intl_gen/pubspec.yaml
	cd json_intl_gen; $(DART_BIN) pub get

test: node_modules
	cd json_intl; flutter test --coverage --coverage-path ../lcov.info
	$(DART_BIN) json_intl_gen/bin/json_intl_gen.dart -s json_intl/test/data -d json_intl/test/intl.dart -v
	cat lcov.info | node_modules/.bin/lcov-summary

publish: format analyze clean
	test -z "$(shell git status --porcelain)"
	find . -name pubspec.yaml -exec sed -i -e 's/^dependency_overrides:/_dependency_overrides:/g' '{}' ';'
	$(DART_BIN) pub publish -f -C json_intl
	find . -name pubspec.yaml -exec sed -i -e 's/^_dependency_overrides:/dependency_overrides:/g' '{}' ';'
	git tag $(shell grep version json_intl/pubspec.yaml | sed 's/version\s*:\s*/v/g')

publish-gen: format clean
	test -z "$(shell git status --porcelain)"
	find . -name pubspec.yaml -exec sed -i -e 's/^dependency_overrides:/_dependency_overrides:/g' '{}' ';'
	$(DART_BIN) pub publish -f -C json_intl_gen
	find . -name pubspec.yaml -exec sed -i -e 's/^_dependency_overrides:/dependency_overrides:/g' '{}' ';'

.pana:
	cd json_intl; $(DART_BIN) pub global activate pana
	touch $@

analyze: .pana
	cd json_intl; $(DART_BIN) pub global run pana --no-warning --source path .

.PHONY: format format-dart clean publish test analyze
