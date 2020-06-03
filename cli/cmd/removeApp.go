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
	"bufio"
	"crypto/tls"
	"fmt"
	"net/http"
	"os"
	"strings"

	log "github.com/sirupsen/logrus"
	gitlab "github.com/xanzy/go-gitlab"

	"github.com/spf13/cobra"
)

func userConfirmsRemove(appName string) bool {
	message := `

 This command will remove all data from the platform related to the following app:

 %s

 This includes:

 - All app repositories from GitLab, including ALL application source code
 - All app images from GCP Artifact Registry
 - All app configuration data from the Anthos Config Management repository
 - All running applications and any associated platform resources such as load balancers

 This operation is permanent and no deleted data can be recovered.

 Please respond with 'y' or 'yes' to continue, or anything else to cancel:

 `
	fmt.Printf(message, appName)
	reader := bufio.NewReader(os.Stdin)
	response, err := reader.ReadString('\n')
	if err != nil {
		log.Fatal(err)
	}

	response = strings.ToLower(strings.TrimSpace(response))

	if response == "y" || response == "yes" {
		return true
	} else {
		return false
	}
}

var removeAppCmd = &cobra.Command{
	Use:   "app",
	Short: "Remove an app from an Anthos Platform installation",
	Long:  `anthos-platform-cli remove app [app-name]`,
	Run: func(cmd *cobra.Command, args []string) {
		name, err := cmd.Flags().GetString("name")
		if err != nil {
			log.Fatal("Unable to parse name for the application")
		}
		if name == "" {
			log.Fatal("Provide a name for the application")
		}

		if userConfirmsRemove(name) != true {
			log.Printf("Exiting without changes")
			os.Exit(0)
		}

		gitlabHostname, gitlabToken := getGitLabParams(cmd)

		artifactRegistryLocation, err := cmd.Flags().GetString("artifact-registry-location")
		if err != nil {
			log.Fatal("Unable to parse Artifact Registry location")
		}

		// Create SSH keys that will be used to push and pull Git repos
		tmpKeyName := "remove-app"
		tmpKeyPath := name + "/" + tmpKeyName
		resources.CreateSSHKey(tmpKeyName, name)

		// Configure GitLab client TODO pull out into helper
		gitlabInsecure, err := cmd.Flags().GetBool("gitlab-insecure")
		tr := &http.Transport{}
		if gitlabInsecure {
			tr.TLSClientConfig = &tls.Config{InsecureSkipVerify: true}
		}
		httpClient := &http.Client{Transport: tr}
		client := gitlab.NewClient(httpClient, gitlabToken)
		client.SetBaseURL(fmt.Sprintf("https://%s/", gitlabHostname))

		// Delete workload identity binding & SA
		resources.DeleteWorkloadIdentity(name)

		// Remove group (contains both app and -env repos)
		resources.DeleteGroup(client, name)

		// Remove app from ACM and so from clusters
		resources.RemoveAppFromACM(client, name, tmpKeyPath)

		// Remove Artifact Registry repo and credentials
		resources.DeleteRepository(name, artifactRegistryLocation)

	},
}

func init() {
	removeCmd.AddCommand(removeAppCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	removeAppCmd.PersistentFlags().StringP("name", "n", "", "Name of the application")
	removeAppCmd.PersistentFlags().String("template-name", "", "Template project to use as source")
	removeAppCmd.PersistentFlags().String("template-namespace", "platform-admins", "Template namespace")
	removeAppCmd.PersistentFlags().String("artifact-registry-location", "us-central1", "Location for Artifact Registry")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// appCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}
