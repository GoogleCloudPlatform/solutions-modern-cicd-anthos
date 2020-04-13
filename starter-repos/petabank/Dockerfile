# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Use base golang image from Docker Hub
FROM golang:1.12

# Download the dlv (delve) debugger for go (you can comment this out if unused)
RUN go get -u github.com/go-delve/delve/cmd/dlv

WORKDIR /src/creditcard

# Install dependencies in go.mod and go.sum
COPY go.mod go.sum ./
RUN go mod download

# Copy rest of the application source code
COPY . ./

# Compile the application to /app.
RUN go build -o /app -v ./

# If you want to use the debugger, you need to modify the entrypoint to the
# container and point it to the "dlv debug" command:
#   * UNCOMMENT the following ENTRYPOINT statement,
#   * COMMENT OUT the last ENTRYPOINT statement
# Start the "dlv debug" server on port 3000 of the container. (Note that the
# application process will NOT start until the debugger is attached.)
#ENTRYPOINT ["dlv", "debug", "./cmd/creditcard",  "--api-version=2", "--headless", "--listen=:3000", "--log"]

# If you want to run WITHOUT the debugging server:
#   * COMMENT OUT the previous ENTRYPOINT statements,
#   * UNCOMMENT the following ENTRYPOINT statement.
ENTRYPOINT ["/app"]

