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

	"github.com/spf13/cobra"
)

func init() {
	rootCmd.AddCommand(versionCmd)
}

var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Prints the version of this application",
	Long:  `This is the X Version of the application`,
	Run: func(cmd *cobra.Command, args []string) {

		version := resources.GetBuildVersion()
		binary := resources.BinaryName()

		// binary := "Anthos Platform"

		fmt.Printf("%s: %s\n", binary, version)
	},
}
