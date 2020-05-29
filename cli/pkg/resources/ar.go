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
	"fmt"
	"os/exec"
	"strings"

	log "github.com/sirupsen/logrus"
)

func addSABinding(repoName string, serviceAccountEmail string, location string) {

	locationArg := "--location=" + location
	memberArg := "--member=serviceAccount:" + serviceAccountEmail
	roleArg := "--role=roles/artifactregistry.writer"

	cmd := exec.Command("gcloud",
		"beta",
		"artifacts",
		"repositories",
		"add-iam-policy-binding",
		repoName,
		locationArg,
		memberArg,
		roleArg)
	output, err := cmd.CombinedOutput()

	if err != nil {
		log.Fatalf("Unable to add binding for service account %v: %s\n", serviceAccountEmail, output)
	}
}

func removeSABinding(repoName string, serviceAccountEmail string, location string) {

	locationArg := "--location=" + location
	memberArg := "--member=serviceAccount:" + serviceAccountEmail
	roleArg := "--role=roles/artifactregistry.writer"

	cmd := exec.Command("gcloud",
		"beta",
		"artifacts",
		"repositories",
		"remove-iam-policy-binding",
		repoName,
		locationArg,
		memberArg,
		roleArg)
	output, err := cmd.CombinedOutput()

	if err != nil {
		log.Fatalf("Unable to remove binding for service account %v: %s\n", serviceAccountEmail, output)
	}
}

func constructSA(repoName string, projectName string) (string, string) {

	serviceAccountName := repoName + "-push"
	serviceAccountEmail := serviceAccountName + "@" + projectName + ".iam.gserviceaccount.com"

	return serviceAccountName, serviceAccountEmail
}

func constructRepo(repoName string, projectName string, location string) string {

	return location + "-docker.pkg.dev/" + projectName + "/" + repoName
}

// CreateRepository creates a repo within AR
func CreateRepository(repoName string, location string) (string, string) {
	locationArg := "--location=" + location
	projectName := GetCurrentProject()

	cmd := exec.Command("gcloud",
		"beta",
		"artifacts",
		"repositories",
		"list",
		"--format=value(AR.name)",
		locationArg)
	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Fatalf("Unable to list Artifact Registry repos: %v\n%s", err, output)
	}

	fullRepoName := fmt.Sprintf("projects/%s/locations/%s/repositories/%s",
		projectName, location, repoName)
	if strings.Contains(string(output), fullRepoName) {
		log.Printf("Artifact Registry repo %v already exists", repoName)
	} else {
		formatArg := "--repository-format=docker"
		log.Printf("Creating AR repository %v in location %v", repoName, location)

		cmd := exec.Command("gcloud",
			"beta",
			"artifacts",
			"repositories",
			"create",
			repoName,
			locationArg,
			formatArg)

		output, err := cmd.CombinedOutput()
		if err != nil {
			log.Fatalf("Unable to create Artifact Registry repository %v: %s\n", repoName, output)
		}
	}

	serviceAccountName, serviceAccountEmail := constructSA(repoName, projectName)
	CreateSA(serviceAccountName, repoName)
	addSABinding(repoName, serviceAccountEmail, location)

	repo := constructRepo(repoName, projectName, location)
	key := CreateSAKey(serviceAccountEmail)

	return repo, key

}

// DeleteRepository deletes a repo within AR
func DeleteRepository(repoName string, location string) {

	locationArg := "--location=" + location
	quietArg := "--quiet"

	log.Printf("Deleting AR repository %v in location %v", repoName, location)

	projectName := GetCurrentProject()
	_, serviceAccountEmail := constructSA(repoName, projectName)

	removeSABinding(repoName, serviceAccountEmail, location)
	DeleteSA(serviceAccountEmail)

	cmd := exec.Command("gcloud",
		"beta",
		"artifacts",
		"repositories",
		"delete",
		repoName,
		locationArg,
		quietArg)

	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Fatalf("Unable to delete Artifact Registry repository %v: %s\n", repoName, output)
	}
}
