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
	"os"

	log "github.com/sirupsen/logrus"
	gitlab "github.com/xanzy/go-gitlab"

	"github.com/spf13/cobra"
)

// addClusterCmd represents the cluster addition command
var addClusterCmd = &cobra.Command{
	Use:   "cluster",
	Short: "Add a cluster to an Anthos Platform installation",
	Long:  `anthos-platform-cli add cluster [cluster-name]`,
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

		// Create a directory to store any assets we create for the cluster.
		err = os.MkdirAll(clusterName, os.ModePerm)
		if err != nil {
			log.Fatalf("Unable to create directory (%s): %v", clusterName, err)
		}

		sshKeyName := "deploy-key"
		sshKeyPath := fmt.Sprintf("%s/%s", clusterName, sshKeyName)
		resources.CreateSSHKey(sshKeyName, clusterName)
		acmRepoNamespace := "platform-admins"
		acmRepoName := "anthos-config-management"
		acmRepo := resources.CloneRepo(client, acmRepoNamespace, acmRepoName, sshKeyPath)
		deployKeyName := fmt.Sprintf("Adding cluster: %s", clusterName)
		resources.AddDeployKey(client, acmRepoNamespace+"/"+acmRepoName, sshKeyPath+".pub", deployKeyName, false)

		resources.ApplyACMOperator()
		resources.CreateACMGitSecret(clusterName, sshKeyPath)

		resources.GetACMOperator()
		resources.ApplyACMConfig(clusterName, gitlabHostname, acmRepoNamespace, acmRepoName)

		// TODO Check that you are synced...
		// ./nomos status --contexts $(kubectl config current-context)

		project := resources.GetProject(client, acmRepoNamespace+"/"+acmRepoName)
		resources.AddClusterToACM(acmRepo, clusterName, env, gitlabHostname, sshKeyPath, project.RunnersToken)

		// TODO add Vet stage to ACM repo CI
	},
}

func init() {
	addCmd.AddCommand(addClusterCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	addClusterCmd.PersistentFlags().StringP("name", "n", "", "Name of the cluster")
	addClusterCmd.PersistentFlags().StringP("environment", "e", "prod", "Environment of the cluster (default: prod)")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// clusterCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}
