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
	"fmt"
	"os"

	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"

	homedir "github.com/mitchellh/go-homedir"
	"github.com/spf13/viper"
)

var cfgFile string

// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
	Use:   "anthos-platform-cli",
	Short: "Manage an Anthos Platform installation",
	Long: `Manage an Anthos Platform installation.

Add applications and clusters:

anthos-platform-cli add < app | cluster > `,
	// Uncomment the following line if your bare application
	// has an action associated with it:
	//	Run: func(cmd *cobra.Command, args []string) { },
}

// Execute adds all child commands to the root command and sets flags appropriately.
// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func getGitLabParams(cmd *cobra.Command) (string, string) {
	gitlabHostname, err := cmd.Flags().GetString("gitlab-hostname")
	if err != nil {
		log.Fatal("Unable to parse gitlab-hostname.")
	}
	if gitlabHostname == "" {
		log.Fatal("Provide a gitlab-hostname.")
	}

	gitlabToken, err := cmd.Flags().GetString("gitlab-token")
	if gitlabToken == "" {
		log.Fatal("Provide an Access Token for authenticating with the GitLab API")
	}
	return gitlabHostname, gitlabToken
}

func init() {
	cobra.OnInitialize(initConfig)

	// Here you will define your flags and configuration settings.
	// Cobra supports persistent flags, which, if defined here,
	// will be global for your application.

	rootCmd.PersistentFlags().String("gitlab-hostname", "", "Hostname for your gitlab instance")
	rootCmd.PersistentFlags().String("gitlab-token", "", "Access Token from GitLab for admin actions")
	rootCmd.PersistentFlags().Bool("gitlab-insecure", false, "Skip SSL validation for GitLab requests")
	rootCmd.PersistentFlags().StringVar(&cfgFile, "config", ".apctl.yaml", "config file (default is .apctl.yaml)")

	// Cobra also supports local flags, which will only run
	// when this action is called directly.
	rootCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}

// initConfig reads in config file and ENV variables if set.
func initConfig() {
	if cfgFile != "" {
		// Use config file from the flag.
		viper.SetConfigFile(cfgFile)
	} else {
		// Find home directory.
		home, err := homedir.Dir()
		if err != nil {
			fmt.Println(err)
			os.Exit(1)
		}

		// Search config in home directory with name ".apctl" (without extension).
		viper.AddConfigPath(home)
		viper.SetConfigName(".apctl.yaml")
	}

	viper.AutomaticEnv() // read in environment variables that match

	// If a config file is found, read it in.
	if err := viper.ReadInConfig(); err == nil {
		fmt.Println("Using config file:", viper.ConfigFileUsed())
	}
}
