package resources

import (
	"os/exec"
	"strings"

	log "github.com/sirupsen/logrus"
)

func checkForGcloud() {
	// Check for kubectl being in the PATH
	cmd := exec.Command("gcloud", "version")
	clientVersion, err := cmd.CombinedOutput()
	if err != nil {
		log.Fatalf("Failed to find gcloud: %v\n%s", err, clientVersion)
	}

	// Check that gcloud can authenticate properly
	cmd = exec.Command("gcloud", "auth", "print-identity-token")
	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Fatalf("Unable to authenticate using gcloud: %v\n%s", err, output)
	}
}

func GetCurrentProject() string {

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
