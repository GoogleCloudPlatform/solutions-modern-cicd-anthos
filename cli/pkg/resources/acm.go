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
	"encoding/base64"
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"strings"
	"time"

	log "github.com/sirupsen/logrus"

	gitlab "github.com/xanzy/go-gitlab"

	"gopkg.in/src-d/go-git.v4"
	"gopkg.in/src-d/go-git.v4/plumbing/object"
)

func AddAppToACM(client *gitlab.Client, name string, runnersToken string, sshKeyPath string) {
	// Set variables about ACM repo
	gitlabHostname := client.BaseURL().Hostname()
	acmRepoNamespace := "platform-admins"
	acmRepoName := "anthos-config-management"

	// Add deploy key to source project so that we can clone it
	sourceRepo := GetProject(client, fmt.Sprintf("%s/%s", acmRepoNamespace, acmRepoName))
	keyTitle := fmt.Sprintf("Anthos Platform CLI Cloning: %s", acmRepoName)
	AddDeployKey(client, sourceRepo.ID, sshKeyPath+".pub", keyTitle, false)

	// Clone ACM repo
	r := CloneRepo(client, acmRepoNamespace, acmRepoName, sshKeyPath)
	DeleteDeployKey(client, sourceRepo.ID, keyTitle)

	// Get a worktree so we can operate on the files
	w, err := r.Worktree()
	if err != nil {
		log.Fatalf("Unable to read worktree from respository: %v", err)
	}

	// Read all files from the template directory
	templatePath := "templates/_namespace-template/"
	templateFiles, err := w.Filesystem.ReadDir(templatePath)
	if err != nil {
		log.Fatalf("Unable to read template dir (%s) from respository: %v", templatePath, err)
	}

	// Create the new namespace path
	newNamespacePath := "namespaces/managed-apps/" + name + "/"
	w.Filesystem.MkdirAll(newNamespacePath, os.ModePerm)

	// Copy each of the files in the template into its new directory and
	// replace the necessary variables.
	for _, file := range templateFiles {
		filename := file.Name()

		newFileName := newNamespacePath + filename
		templateFileName := templatePath + filename

		// Open the template file
		in, err := w.Filesystem.Open(templateFileName)
		if err != nil {
			log.Fatalf("Unable to open file %v: %v", templateFileName, err)
		}
		// Create the new file
		out, err := w.Filesystem.Create(newFileName)
		if err != nil {
			log.Fatalf("Unable to create file %v: %v", newFileName, err)
		}

		// Copy the template file to the new file
		inBytes, err := ioutil.ReadAll(in)
		in.Close()
		if err != nil {
			log.Fatalf("Unable to read file %v: %v", templateFileName, err)
		}

		// Replace APP_NAME with the name of the new app
		outString := strings.ReplaceAll(string(inBytes), "APP_NAME", name)
		// Replace GITLAB_HOSTNAME
		outString = strings.ReplaceAll(string(outString), "GITLAB_HOSTNAME", gitlabHostname)
		// Replace GitLab Runner registration token
		encodedRT := base64.StdEncoding.EncodeToString([]byte(runnersToken))
		outString = strings.ReplaceAll(string(outString), "RUNNER_REGISTRATION_TOKEN_BASE64", encodedRT)
		// Replace PROJECT_ID with current project
		outString = strings.ReplaceAll(string(outString), "PROJECT_ID", GetCurrentProject())

		_, err = out.Write([]byte(outString))
		defer out.Close()
		if err != nil {
			log.Fatalf("Unable to write to file %v: %v", inBytes, err)
		}

		// Stage the new file in the index
		w.Add(newFileName)
	}

	_, err = w.Commit("Add new app: "+name, &git.CommitOptions{
		Author: &object.Signature{
			Name:  "Anthos Platform CLI",
			Email: "anthos-platform-cli@" + gitlabHostname,
			When:  time.Now(),
		},
	})
	if err != nil {
		log.Fatalf("Unable to commit: %v", err)
	}

	// Set up authentication for this push, then tear it down
	deployKeyName := fmt.Sprintf("Adding %s to ACM repo", name)
	acmPID := acmRepoNamespace + "/" + acmRepoName
	AddDeployKey(client, acmPID, sshKeyPath+".pub", deployKeyName, true)
	defer DeleteDeployKey(client, acmPID, deployKeyName)

	err = r.Push(&git.PushOptions{Auth: GetSSHAuth(sshKeyPath)})
	if err != nil {
		log.Fatalf("Unable to push commit: %v", err)
	}

}

func RemoveAppFromACM(client *gitlab.Client, name string, sshKeyPath string) {
	// Set variables related to ACM repo
	gitlabHostname := client.BaseURL().Hostname()
	acmRepoNamespace := "platform-admins"
	acmRepoName := "anthos-config-management"

	// Add deploy key to source project so that we can clone it
	sourceRepo := GetProject(client, fmt.Sprintf("%s/%s", acmRepoNamespace, acmRepoName))
	keyTitle := fmt.Sprintf("Anthos Platform CLI Cloning: %s", acmRepoName)
	AddDeployKey(client, sourceRepo.ID, sshKeyPath+".pub", keyTitle, false)

	// Clone ACM repo
	r := CloneRepo(client, acmRepoNamespace, acmRepoName, sshKeyPath)
	DeleteDeployKey(client, sourceRepo.ID, keyTitle)

	// Get a worktree so we can operate on the files
	w, err := r.Worktree()
	if err != nil {
		log.Fatalf("Unable to read worktree from respository: %v", err)
	}

	// Construct path and remove from tree
	removePath := "namespaces/managed-apps/" + name + "/*"
	w.RemoveGlob(removePath)

	_, err = w.Commit("Remove app: "+name, &git.CommitOptions{
		Author: &object.Signature{
			Name:  "Anthos Platform CLI",
			Email: "anthos-platform-cli@" + gitlabHostname,
			When:  time.Now(),
		},
	})
	if err != nil {
		log.Fatalf("Unable to commit: %v", err)
	}

	// Set up authentication for this push, then tear it down
	deployKeyName := fmt.Sprintf("Removing %s from ACM repo", name)
	acmPID := acmRepoNamespace + "/" + acmRepoName
	AddDeployKey(client, acmPID, sshKeyPath+".pub", deployKeyName, true)
	defer DeleteDeployKey(client, acmPID, deployKeyName)

	err = r.Push(&git.PushOptions{Auth: GetSSHAuth(sshKeyPath)})
	if err != nil {
		log.Fatalf("Unable to push commit: %v", err)
	}
}

func GetACMOperator() {
	log.Printf("Downloading ACM Operator manifest (using gsutil)...")
	checkForGcloud()

	acmOperatorPath := "gs://config-management-release/released/latest/config-management-operator.yaml"
	cmd := exec.Command("gsutil", "cp", acmOperatorPath, ".")
	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Fatalf("Unable to download config management operator: %v\n%s", err, output)
	}
}

func ApplyACMOperator() {
	log.Printf("Installing ACM Operator...")
	checkForKubectl()
	acmOperatorURL := "config-management-operator.yaml"
	cmd := exec.Command("kubectl", "apply", "-f", acmOperatorURL)
	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Fatalf("Unable to install config management operator: %v\n%s", err, output)
	}
}

func CreateACMGitSecret(clusterName string, sshKeyPath string) {
	log.Printf("Creating ACM Git credentials secret...")
	checkForKubectl()

	configFileName := fmt.Sprintf("%s/git-creds.yaml", clusterName)
	cmd := exec.Command("kubectl", "create", "secret", "generic", "git-creds",
		"--namespace=config-management-system", "--dry-run", "-o", "yaml",
		fmt.Sprintf("--from-file=ssh=./%s", sshKeyPath))
	configFileContents, err := cmd.CombinedOutput()
	if err != nil {
		log.Fatalf("Unable to get output from create secret command: %v", err)
	}
	err = ioutil.WriteFile(configFileName, []byte(configFileContents), os.ModePerm)
	if err != nil {
		log.Fatalf("Unable to write Git credentials secret: %v", err)
	}
	cmd = exec.Command("kubectl", "apply", "-f", configFileName)
	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Fatalf("Unable to apply Git credentials secret for config management operator: %v\n%s", err, output)
	}
}

func ApplyACMConfig(clusterName string, gitlabHostname string, acmRepoNamespace string, acmRepoName string) {
	log.Printf("Applying ACM config...")
	checkForKubectl()
	configFileName := fmt.Sprintf("%s/config-management.yaml", clusterName)
	configFileContents := `apiVersion: configmanagement.gke.io/v1
kind: ConfigManagement
metadata:
  name: config-management
spec:
  # clusterName is required and must be unique among all managed clusters
  clusterName: CLUSTERNAME
  git:
    syncRepo: git@GITLAB_HOSTNAME:ACM_REPO_NAMESPACE/ACM_REPO_NAME.git
    syncBranch: master
    secretType: ssh
`
	configFileContents = strings.ReplaceAll(configFileContents, "CLUSTERNAME", clusterName)
	configFileContents = strings.ReplaceAll(configFileContents, "GITLAB_HOSTNAME", gitlabHostname)
	configFileContents = strings.ReplaceAll(configFileContents, "ACM_REPO_NAMESPACE", acmRepoNamespace)
	configFileContents = strings.ReplaceAll(configFileContents, "ACM_REPO_NAME", acmRepoName)
	err := ioutil.WriteFile(configFileName, []byte(configFileContents), os.ModePerm)
	if err != nil {
		log.Fatal("Unable to write config managemnt config to disk: %v", err)
	}
	cmd := exec.Command("kubectl", "apply", "-f", configFileName)
	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Fatalf("Unable to create Git credentials secret for config management operator: %v\n%s", err, output)
	}
}

func AddClusterToACM(r *git.Repository, clusterName string, env string, gitlabHostname string, sshKeyPath string, runnersToken string) {
	// Get a worktree so we can operate on the files
	w, err := r.Worktree()
	if err != nil {
		log.Fatalf("Unable to read worktree from respository: %v", err)
	}

	createClusterFile(w, clusterName, env)
	createClusterSelectorFile(w, clusterName)
	createACMTestRunnerConfig(w, clusterName, gitlabHostname)

	_, err = w.Commit("Add new cluster: "+clusterName, &git.CommitOptions{
		Author: &object.Signature{
			Name:  "Anthos Platform CLI",
			Email: "anthos-platform-cli@" + gitlabHostname,
			When:  time.Now(),
		},
	})
	if err != nil {
		log.Fatalf("Unable to commit: %v", err)
	}

	addRunnerRegistrationTokenSecret(clusterName, runnersToken)

	err = r.Push(&git.PushOptions{Auth: GetSSHAuth(sshKeyPath)})
	if err != nil {
		log.Fatalf("Unable to push commit: %v", err)
	}

}

func createClusterFile(w *git.Worktree, clusterName string, env string) {
	clusterConfigName := fmt.Sprintf("clusterregistry/%s.yaml", clusterName)
	clusterConfigContents := `
kind: Cluster
apiVersion: clusterregistry.k8s.io/v1alpha1
metadata:
  name: CLUSTERNAME
  labels:
    environment: ENV
    clusterName: CLUSTERNAME
`
	clusterConfigContents = strings.ReplaceAll(clusterConfigContents, "CLUSTERNAME", clusterName)
	clusterConfigContents = strings.ReplaceAll(clusterConfigContents, "ENV", env)

	clusterFile, err := w.Filesystem.Create(clusterConfigName)
	if err != nil {
		log.Fatalf("Unable to create cluster config file: %v", err)
	}
	_, err = clusterFile.Write([]byte(clusterConfigContents))
	if err != nil {
		log.Fatalf("Unable to write cluster config file: %v", err)
	}
	_, err = w.Add(clusterConfigName)
	if err != nil {
		log.Fatalf("Unable to add cluster config: %v", err)
	}
}

func createClusterSelectorFile(w *git.Worktree, clusterName string) {
	clusterSelectorName := fmt.Sprintf("clusterregistry/selector-%s.yaml", clusterName)
	clusterSelectorContents := `kind: ClusterSelector
apiVersion: configmanagement.gke.io/v1
metadata:
  name: CLUSTERNAME
spec:
  selector:
    matchLabels:
      clusterName: CLUSTERNAME
`
	clusterSelectorContents = strings.ReplaceAll(clusterSelectorContents, "CLUSTERNAME", clusterName)
	clusterSelectorFile, err := w.Filesystem.Create(clusterSelectorName)
	if err != nil {
		log.Fatalf("Unable to create cluster selector config file: %v", err)
	}
	_, err = clusterSelectorFile.Write([]byte(clusterSelectorContents))
	if err != nil {
		log.Fatalf("Unable to write cluster selector config file: %v", err)
	}
	_, err = w.Add(clusterSelectorName)
	if err != nil {
		log.Fatalf("Unable to add cluster selector config: %v", err)
	}
}

func createACMTestRunnerConfig(w *git.Worktree, clusterName string, gitlabHostname string) {
	acmTestConfigName := fmt.Sprintf("namespaces/acm-tests/gitlab-runner-configmap-%s.yaml", clusterName)
	acmTestConfigFile, err := w.Filesystem.Create(acmTestConfigName)
	if err != nil {
		log.Fatalf("Unable to create ACM test config file: %v", err)
	}
	acmTestConfigContents := `apiVersion: v1
kind: ConfigMap
metadata:
  name: gitlab-runner-config-acm
  annotations:
    configmanagement.gke.io/cluster-selector: CLUSTERNAME
data:
  CI_SERVER_URL: https://GITLAB_HOSTNAME
  KUBERNETES_IMAGE: ubuntu:16.04
  KUBERNETES_NAMESPACE: acm-tests
  REGISTER_LOCKED: "true"
  RUNNER_EXECUTOR: kubernetes
  RUNNER_REQUEST_CONCURRENCY: "1"
  RUNNER_TAG_LIST: app:acm-tests, cluster:CLUSTERNAME
`
	acmTestConfigContents = strings.ReplaceAll(acmTestConfigContents, "CLUSTERNAME", clusterName)
	acmTestConfigContents = strings.ReplaceAll(acmTestConfigContents, "GITLAB_HOSTNAME", gitlabHostname)

	_, err = acmTestConfigFile.Write([]byte(acmTestConfigContents))
	if err != nil {
		log.Fatalf("Unable to write cluster confi file: %v", err)
	}
	_, err = w.Add(acmTestConfigName)
	if err != nil {
		log.Fatalf("Unable to add cluster config: %v", err)
	}
}

func addRunnerRegistrationTokenSecret(clusterName string, runnersToken string) {
	log.Printf("Creating ACM test runner secret...")
	runnerSecretPath := fmt.Sprintf("%s/gitlab-runner-secret.yaml", clusterName)
	runnerSecretContents := `apiVersion: v1
kind: Secret
metadata:
  name: gitlab-runner
data:
  runner-registration-token: RUNNER_REGISTRATION_TOKEN_BASE64
`
	runnerSecretContentsEncoded := base64.StdEncoding.EncodeToString([]byte(runnersToken))
	runnerSecretContents = strings.ReplaceAll(runnerSecretContents, "RUNNER_REGISTRATION_TOKEN_BASE64", runnerSecretContentsEncoded)

	err := ioutil.WriteFile(runnerSecretPath, []byte(runnerSecretContents), os.ModePerm)
	if err != nil {
		log.Fatalf("Unable to write cluster config file: %v", err)
	}

	cmd := exec.Command("kubectl", "get", "ns", "acm-tests")
	output, err := cmd.CombinedOutput()
	if err != nil && strings.Contains(string(output), "not found") {
		cmd := exec.Command("kubectl", "create", "namespace", "acm-tests")
		output, err := cmd.CombinedOutput()
		if err != nil {
			log.Fatalf("Unable to create namespace for acm-tests: %v\n%s", err, output)
		}
	}

	cmd = exec.Command("kubectl", "apply", "-f", runnerSecretPath)
	output, err = cmd.CombinedOutput()
	if err != nil {
		log.Fatalf("Unable to create Git credentials secret for config management operator: %v\n%s", err, output)
	}
}

func RemoveACM() {
	log.Printf("Removing ACM from cluster..")
	checkForKubectl()
	cmd := exec.Command("kubectl", "delete", "ns", "config-management-system", "--wait")
	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Fatalf("Unable to remove ACM namespace: %v\n%s", err, output)
	}

	cmd = exec.Command("kubectl", "delete", "ns", "acm-tests", "--wait")
	output, err = cmd.CombinedOutput()
	if err != nil {
		log.Fatalf("Unable to remove ACM tests namespace: %v\n%s", err, output)
	}
}
