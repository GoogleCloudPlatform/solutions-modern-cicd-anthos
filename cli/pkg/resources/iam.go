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
	"io/ioutil"
	"os"
	"os/exec"
	"strings"

	log "github.com/sirupsen/logrus"
)

func CreateSA(name string, description string) {
	filterArg := fmt.Sprintf("--filter=displayName=%s", name)
	formatArg := fmt.Sprintf("--format=value(displayName)")
	cmd := exec.Command("gcloud",
		"iam",
		"service-accounts",
		"list",
		filterArg,
		formatArg)
	output, err := cmd.CombinedOutput()

	if strings.Contains(string(output), name) {
		log.Printf("Service account %v already exists", name)
		return
	}

	log.Printf("Creating service account %v", name)

	displayNameArg := "--display-name=" + name
	descriptionArg := "--description=" + description
	cmd = exec.Command("gcloud",
		"iam",
		"service-accounts",
		"create",
		name,
		displayNameArg,
		descriptionArg)
	output, err = cmd.CombinedOutput()

	if err != nil {
		log.Fatalf("Unable to create service account %v: %s\n", name, output)
	}
}

func DeleteSA(serviceAccountName string) {

	log.Printf("Deleting service account %v", serviceAccountName)

	cmd := exec.Command("gcloud",
		"iam",
		"service-accounts",
		"delete",
		serviceAccountName)
	output, err := cmd.CombinedOutput()

	if err != nil {
		log.Fatalf("Unable to delete service account %v: %s\n", serviceAccountName, output)
	}
}

func CreateSAKey(serviceAccountEmail string) string {

	serviceAccountArg := "--iam-account=" + serviceAccountEmail

	tmpDir, err := ioutil.TempDir("", "anthos-platform-cli-*")
	if err != nil {
		log.Fatal("Cannot create temporary directory", err)
	}

	defer os.RemoveAll(tmpDir)
	filename := tmpDir + "/key.json"

	cmd := exec.Command("gcloud",
		"iam",
		"service-accounts",
		"keys",
		"create",
		serviceAccountArg,
		filename)

	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Fatalf("Unable to create key for service account %v: %s\n", serviceAccountEmail, output)
	}

	buf, err := ioutil.ReadFile(filename)
	if err != nil {
		log.Fatalf("Unable to read keyfile %v: %v\n", filename, output)
	}

	return string(buf)
}

func AddSAIAMPolicyBinding(name string, role string, serviceAccountEmail string) {

	memberArg := "--member=serviceAccount:" + serviceAccountEmail
	roleArg := "--role=" + role

	cmd := exec.Command("gcloud",
		"iam",
		"service-accounts",
		"add-iam-policy-binding",
		name,
		memberArg,
		roleArg)
	output, err := cmd.CombinedOutput()

	if err != nil {
		log.Fatalf("Unable to add binding for service account %v: %s\n", serviceAccountEmail, output)
	}
}

func RemoveSAIAMPolicyBinding(name string, role string, serviceAccountEmail string) {

	memberArg := "--member=serviceAccount:" + serviceAccountEmail
	roleArg := "--role=" + role

	cmd := exec.Command("gcloud",
		"iam",
		"service-accounts",
		"remove-iam-policy-binding",
		name,
		memberArg,
		roleArg)
	output, err := cmd.CombinedOutput()

	if err != nil {
		log.Fatalf("Unable to remove binding for service account %v: %s\n", serviceAccountEmail, output)
	}
}
