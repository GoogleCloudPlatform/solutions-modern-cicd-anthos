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
	"strings"

	log "github.com/sirupsen/logrus"
)

func checkForGcloud() {
	// Check for kubectl being in the PATH
	cmd := exec.Command("gcloud", "version")
	clientVersion, err := cmd.CombinedOutput()
	if err != nil {
		log.Fatalf("Failed to find gcloud: %v\n%s", err, clientVersion)
	}

	// Check that gcloud can authenticate properly
	cmd = exec.Command("gcloud", "auth", "print-identity-token")
	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Fatalf("Unable to authenticate using gcloud: %v\n%s", err, output)
	}
}

// GetCurrentProject returns the current, active project for the authenticated gcloud user
func GetCurrentProject() string {

    // derived from: gcloud config list --format 'value(core.project)' 2>/dev/null
    cmd := exec.Command("gcloud",
        "config",
        "list",
        "--format=value(core.project)")

	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Fatalf("Unable to retrieve current project ID: %s\n", output)
	}

	return strings.TrimSuffix(string(output), "\n")
}
