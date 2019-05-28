# Copyright 2019 Level 25
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

OOS ?= $(shell go env GOOS)
GOARCH = amd64

GO_FILES := $(shell find . -type f -name '*.go' -not -path "./vendor/*")
GO_LDFLAGS := '-extldflags "-static"
GO_LDFLAGS += -w -s
GO_LDFLAGS += '

bin/scale: $(GO_FILES)
	GOARCH=$(GOARCH) GOOS=$(GOOS) CGO_ENABLED=0 go build -ldflags $(GO_LDFLAGS) -o $@ cmd/scale/main.go

bin/scale-linux: $(GO_FILES)
	GOARCH=$(GOARCH) GOOS=linux CGO_ENABLED=0 go build -ldflags $(GO_LDFLAGS) -o $@ cmd/scale/main.go

bin/ecs: $(GO_FILES)
	GOARCH=$(GOARCH) GOOS=$(GOOS) CGO_ENABLED=0 go build -ldflags $(GO_LDFLAGS) -o $@ cmd/ecs/main.go

bin/ecs-linux: $(GO_FILES)
	GOARCH=$(GOARCH) GOOS=linux CGO_ENABLED=0 go build -ldflags $(GO_LDFLAGS) -o $@ cmd/ecs/main.go

.PHONY: test
test: bin/scale
	go test -cover -v -timeout 60s `go list ./... | grep -v vendor`

.PHONY: clean
clean:
	rm bin/*

.PHONY: zip
zip: bin/scale bin/ecs
	cd bin && zip scale.zip scale ecs
	mv bin/scale.zip ./scale.zip
