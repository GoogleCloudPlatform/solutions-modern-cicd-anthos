package resources

import (
	"io/ioutil"
	"os"
	"os/exec"
	"strings"

	log "github.com/sirupsen/logrus"
)

func createSA(repoName string, serviceAccountName string) {

	displaynameArg := "--display-name=" + serviceAccountName
	descriptionArg := "--description=Push images to " + repoName

	log.Printf("Creating service account %v", serviceAccountName)

	cmd := exec.Command("gcloud",
		"iam",
		"service-accounts",
		"create",
		serviceAccountName,
		displaynameArg,
		descriptionArg)
	output, err := cmd.CombinedOutput()

	if err != nil {
		log.Fatalf("Unable to create service account %v: %s\n", serviceAccountName, output)
	}
}

func deleteSA(serviceAccountName string) {

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

func createSAKey(serviceAccountEmail string) string {

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

func getCurrentProject() string {

	cmd := exec.Command("gcloud",
		"config",
		"get-value",
		"project")

	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Fatalf("Unable to retrieve current project ID: %s\n", output)
	}

	return strings.TrimSuffix(string(output), "\n")
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

	projectName := getCurrentProject()
	serviceAccountName, serviceAccountEmail := constructSA(repoName, projectName)
	createSA(repoName, serviceAccountName)
	addSABinding(repoName, serviceAccountEmail, location)

	repo := constructRepo(repoName, projectName, location)
	key := createSAKey(serviceAccountEmail)

	return repo, key

}

// DeleteRepository deletes a repo within AR
func DeleteRepository(repoName string, location string) {

	locationArg := "--location=" + location

	log.Printf("Deleting AR repository %v in location %v", repoName, location)

	projectName := getCurrentProject()
	serviceAccountName, serviceAccountEmail := constructSA(repoName, projectName)

	removeSABinding(repoName, serviceAccountEmail, location)
	deleteSA(serviceAccountName)

	cmd := exec.Command("gcloud",
		"beta",
		"artifacts",
		"repositories",
		"delete",
		repoName,
		locationArg)

	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Fatalf("Unable to create Artifact Registry repository %v: %s\n", repoName, output)
	}
}
