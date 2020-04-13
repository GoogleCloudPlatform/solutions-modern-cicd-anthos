// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package resources

import (
	"os/exec"

	log "github.com/sirupsen/logrus"
)

func checkForKubectl() {
	// Check for kubectl being in the PATH
	cmd := exec.Command("kubectl", "version", "--client=true", "-o", "json")
	clientVersion, err := cmd.CombinedOutput()
	if err != nil {
		log.Fatalf("Failed to find kubectl: %v\n%s", err, clientVersion)
	}

	// Check that kubectl has an active context
	cmd = exec.Command("kubectl", "config", "current-context")
	currentContext, err := cmd.CombinedOutput()
	if err != nil {
		log.Fatalf("Please set a kubectl context before re-running: %v", err)
	}
	log.Printf("Using kubectl context: %s", currentContext)
}
