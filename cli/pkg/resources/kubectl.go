package resources

import (
	"os/exec"

	log "github.com/sirupsen/logrus"
)

func checkForKubectl() {
	// Check for kubectl being in the PATH
	cmd := exec.Command("kubectl", "version", "--client=true", "-o", "json")
	clientVersion, err := cmd.CombinedOutput()
	if err != nil {
		log.Fatalf("Failed to find kubectl: %v\n%s", err, clientVersion)
	}

	// Check that kubectl has an active context
	cmd = exec.Command("kubectl", "config", "current-context")
	currentContext, err := cmd.CombinedOutput()
	if err != nil {
		log.Fatalf("Please set a kubectl context before re-running: %v", err)
	}
	log.Printf("Using kubectl context: %s", currentContext)
}
