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

package cmd

import (
	"anthos-platform/anthos-platform-cli/pkg/resources"
	"crypto/tls"
	"net/http"
	"os"
	"strings"
	"time"

	"fmt"
	"io/ioutil"

	log "github.com/sirupsen/logrus"
	"gopkg.in/src-d/go-git.v4"
	"gopkg.in/src-d/go-git.v4/plumbing/object"

	"github.com/spf13/cobra"

	gitlab "github.com/xanzy/go-gitlab"
)

var addAppCmd = &cobra.Command{
	Use:   "app",
	Short: "Add an app to an Anthos Platform installation",
	Long:  `anthos-platform-cli add app [app-name]`,
	Run: func(cmd *cobra.Command, args []string) {
		name, err := cmd.Flags().GetString("name")
		if err != nil {
			log.Fatal("Unable to parse name for the application")
		}
		if name == "" {
			log.Fatal("Provide a name for the application")
		}

		gitlabHostname, gitlabToken := getGitLabParams(cmd)

		templateNamespace, err := cmd.Flags().GetString("template-namespace")
		if err != nil {
			log.Fatal("Unable to parse template namespace name")
		}
		if templateNamespace == "" {
			log.Fatal("Provide a template namespace.")
		}

		templateName, err := cmd.Flags().GetString("template-name")
		if err != nil {
			log.Fatal("Unable to parse template name")
		}
		if templateName == "" {
			log.Fatal("Provide a template name.")
		}

		artifactRegistryLocation, err := cmd.Flags().GetString("artifact-registry-location")
		if err != nil {
			log.Fatal("Unable to parse Artifact Registry location")
		}

		// Create Artifact Registry repo and credentials
		repo, key := resources.CreateRepository(name, artifactRegistryLocation)

		// Create SSH keys that will be used to push and pull Git repos
		tmpKeyName := "tmp-key"
		tmpKeyPath := name + "/" + tmpKeyName
		manifestWriterKeyName := "manifest-writer"
		manifestWriterKeyPath := name + "/" + manifestWriterKeyName
		resources.CreateSSHKey(tmpKeyName, name)
		resources.CreateSSHKey(manifestWriterKeyName, name)

		// Configure GitLab client
		gitlabInsecure, err := cmd.Flags().GetBool("gitlab-insecure")
		tr := &http.Transport{}
		if gitlabInsecure {
			tr.TLSClientConfig = &tls.Config{InsecureSkipVerify: true}
		}
		httpClient := &http.Client{Transport: tr}
		client := gitlab.NewClient(httpClient, gitlabToken)
		client.SetBaseURL(fmt.Sprintf("https://%s/", gitlabHostname))

		// Create a group namespace to put the projects in
		_ = resources.CreateGroup(client, name)

		// Copy template projects for the app and environment repos
		replaceName := func(w *git.Worktree) *git.Worktree {
			// TODO: Iterate over all files in the repo
			files := []string{"k8s/dev/kustomization.yaml",
				"k8s/dev/deployment.yaml",
				"k8s/stg/kustomization.yaml",
				"k8s/stg/deployment.yaml",
				"k8s/prod/kustomization.yaml",
				"k8s/prod/deployment.yaml"}

			for _, filename := range files {
				file, err := w.Filesystem.OpenFile(filename, os.O_RDWR, os.ModePerm)
				if err != nil {
					log.Fatalf("Unable to open file: %s", filename)
				}
				// Read in the file contents
				inBytes, err := ioutil.ReadAll(file)
				defer file.Close()
				if err != nil {
					log.Fatalf("Unable to read file %v: %v", filename, err)
				}
				file.Truncate(0)
				file.Seek(0, 0)
				outString := strings.ReplaceAll(string(inBytes), templateName, name)
				_, err = file.Write([]byte(outString))
				if err != nil {
					log.Fatalf("Unable to write out template for config")
				}

				w.Add(filename)
				_, err = w.Commit("Fix templated names", &git.CommitOptions{
					Author: &object.Signature{
						Name:  "Anthos Platform CLI",
						Email: "apctl@" + gitlabHostname,
						When:  time.Now(),
					},
				})
				if err != nil {
					log.Fatalf("Unable to commit: %v", err)
				}
			}
			return w
		}

		// Create the main app project from the template
		appProject := resources.CopyProject(client, tmpKeyPath, templateNamespace, templateName, name, name, replaceName)

		// Add variables so that jobs can push to AR repo
		resources.AddVariable(client, appProject.ID, "GCP_AR_REPO", repo, false)
		resources.AddVariable(client, appProject.ID, "GCP_AR_KEY", key, true)

		// Create the associated -env project for the pre-environment configuration
		envProject := resources.CopyProject(client, tmpKeyPath, templateNamespace, templateName+"-env", name, name+"-env")

		// Copy app template in ACM for new app.
		resources.AddAppToACM(client, name, envProject.RunnersToken, tmpKeyPath)

		// Ensure the -env project has the correct tags set from its runners to be able to deploy
		resources.FixRunnerTagsInEnvTemplate(client, name, tmpKeyPath)

		// Create staging branch in the -env project
		resources.CreateBranch(client, envProject.ID, "staging", "master")

		// Add Deploy Keys so we can that CI from the app project can push to the -env project
		deployKeyName := fmt.Sprintf("Push manifests from %s", name)
		resources.AddDeployKey(client, envProject.ID, manifestWriterKeyPath+".pub", deployKeyName, true)

		// Add private key as variable so that app project can push to -env project
		manifestWriterPriv, err := ioutil.ReadFile(manifestWriterKeyPath)
		if err != nil {
			log.Fatal("Unable to read manifest writer key: " + manifestWriterKeyPath)
		}
		resources.AddVariable(client, appProject.ID, "MANIFEST_WRITER_KEY", string(manifestWriterPriv), true)

		// Add Service Accounts for Workload Identity
		resources.CreateWorkloadIdentity(name)

		pipelineURL := "https://" + gitlabHostname + "/" + name + "/" + name + "/pipelines"
		log.Println()
		log.Printf("Your first pipeline run has started. Check on it here: %s", pipelineURL)
	},
}

func init() {
	addCmd.AddCommand(addAppCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	addAppCmd.PersistentFlags().StringP("name", "n", "", "Name of the application")
	addAppCmd.PersistentFlags().String("template-name", "", "Template project to use as source")
	addAppCmd.PersistentFlags().String("template-namespace", "platform-admins", "Template namespace")
	addAppCmd.PersistentFlags().String("artifact-registry-location", "us-central1", "Location for Artifact Registry")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// addAppCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}
