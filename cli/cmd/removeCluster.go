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
	"fmt"
	"time"

	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	gitlab "github.com/xanzy/go-gitlab"
	"gopkg.in/src-d/go-git.v4"
	"gopkg.in/src-d/go-git.v4/plumbing/object"
)

// removeClusterCmd represents the cluster command
var removeClusterCmd = &cobra.Command{
	Use:   "cluster",
	Short: "A brief description of your command",
	Long: `A longer description that spans multiple lines and likely contains examples
and usage of using your command. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
	Run: func(cmd *cobra.Command, args []string) {
		clusterName, err := cmd.Flags().GetString("name")
		if err != nil {
			log.Fatal("Unable to parse name for the cluster")
		}
		if clusterName == "" {
			log.Fatal("Provide a name for the cluster")
		}
		env, err := cmd.Flags().GetString("environment")
		if err != nil {
			log.Fatal("Unable to parse environment for the cluster")
		}
		gitlabHostname, gitlabToken := getGitLabParams(cmd)
		// Configure GitLab client
		client := gitlab.NewClient(nil, gitlabToken)
		client.SetBaseURL(fmt.Sprintf("https://%s/", gitlabHostname))

		// Add temp deploy key to make changes to the repo
		sshKeyName := "delete-cluster"
		sshKeyPath := fmt.Sprintf("%s/%s", clusterName, sshKeyName)
		resources.CreateSSHKey(sshKeyName, clusterName)
		acmRepoNamespace := "platform-admins"
		acmRepoName := "anthos-config-management"
		acmPID := acmRepoNamespace + "/" + acmRepoName
		deployKeyName := fmt.Sprintf("Removing cluster: %s", clusterName)
		resources.AddDeployKey(client, acmPID, sshKeyPath+".pub", deployKeyName, true)
		// Delete the temporary key
		defer resources.DeleteDeployKey(client, acmPID, deployKeyName)

		log.Printf("Removing %s cluster related files from ACM repo.", clusterName)
		acmRepo := resources.CloneRepo(client, acmRepoNamespace, acmRepoName, sshKeyPath)
		w, err := acmRepo.Worktree()
		if err != nil {
			log.Fatalf("Unable to get working tree for ACM repo: %v", err)
		}
		clusterRegistryFile := fmt.Sprintf("clusterregistry/%s-%s.yaml", env, clusterName)
		w.Remove(clusterRegistryFile)
		clusterSelectorFile := fmt.Sprintf("clusterregistry/selector-%s.yaml", clusterName)
		w.Remove(clusterSelectorFile)
		acmTestFile := fmt.Sprintf("namespaces/acm-tests/gitlab-runner-configmap-%s.yaml", clusterName)
		w.Remove(acmTestFile)

		_, err = w.Commit("Remove cluster: "+clusterName, &git.CommitOptions{
			Author: &object.Signature{
				Name: "Anthos Platform CLI",
				// TODO Get Gitlab Hostname and use as email domain
				Email: "apctl@" + gitlabHostname,
				When:  time.Now(),
			},
		})
		if err != nil {
			log.Fatalf("Unable to commit: %v", err)
		}

		err = acmRepo.Push(&git.PushOptions{Auth: resources.GetSSHAuth(sshKeyPath)})
		if err != nil {
			log.Fatalf("Unable to push commit: %v", err)
		}

	},
}

func init() {
	removeCmd.AddCommand(removeClusterCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	removeClusterCmd.PersistentFlags().StringP("name", "n", "", "Name of the cluster")
	removeClusterCmd.PersistentFlags().StringP("environment", "e", "prod", "Environment of the cluster (default: prod)")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// clusterCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}
