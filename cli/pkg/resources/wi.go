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

	log "github.com/sirupsen/logrus"
)

func getGSAName(appName string) string {
	return appName + "-gsa"
}

func getBindingName(projectID string, gsaName string) string {
	return fmt.Sprintf("%s@%s.iam.gserviceaccount.com", gsaName, projectID)
}

func getWiName(projectID string, appName string) string {
	return fmt.Sprintf("%s.svc.id.goog[%s/%s-ksa]", projectID, appName, appName)
}

// CreateWorkloadIdentity creates SA and binding for WI
// See https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#creating_a_relationship_between_ksas_and_gsas
func CreateWorkloadIdentity(appName string) {

	log.Printf("Creating workload identity for %s", appName)

	projectID := GetCurrentProject()
	gsaName := getGSAName(appName)
	CreateSA(gsaName, "Map KSA to GSA for "+appName)

	bindingName := getBindingName(projectID, gsaName)
	wiName := getWiName(projectID, appName)
	AddSAIAMPolicyBinding(bindingName, "roles/iam.workloadIdentityUser", wiName)
}

// DeleteWorkloadIdentity deletes SA and binding for WI
func DeleteWorkloadIdentity(appName string) {

	log.Printf("Removing workload identity for %s", appName)

	projectID := GetCurrentProject()
	gsaName := getGSAName(appName)
	bindingName := getBindingName(projectID, gsaName)
	wiName := getWiName(projectID, appName)
	RemoveSAIAMPolicyBinding(bindingName, "roles/iam.workloadIdentityUser", wiName)
	DeleteSA(bindingName)
}
