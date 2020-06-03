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
	"io/ioutil"
	"net"
	"os"
	"strings"
	"time"

	log "github.com/sirupsen/logrus"

	gitlab "github.com/xanzy/go-gitlab"
	"gopkg.in/src-d/go-git.v4"
	"gopkg.in/src-d/go-git.v4/config"
	"gopkg.in/src-d/go-git.v4/plumbing/object"

	"golang.org/x/crypto/ssh"
	"gopkg.in/src-d/go-billy.v4/memfs"
	ssh2 "gopkg.in/src-d/go-git.v4/plumbing/transport/ssh"
	"gopkg.in/src-d/go-git.v4/storage/memory"
)

func CreateGroup(client *gitlab.Client, name string) *gitlab.Group {
	log.Printf("Creating group: %s", name)
	group, err := GetGroup(client, name)
	if group != nil && err == nil {
		log.Printf("Group %s already exists. Continuing...", name)
		return group
	}
	g := &gitlab.CreateGroupOptions{
		Name:       gitlab.String(name),
		Visibility: gitlab.Visibility(gitlab.InternalVisibility),
		Path:       gitlab.String(name),
	}
	group, _, err = client.Groups.CreateGroup(g)
	if err != nil {
		log.Fatal(err)
	}
	return group
}

func DeleteGroup(client *gitlab.Client, name string) {
	log.Printf("Deleting group: %s", name)
	group, err := GetGroup(client, name)
	if group == nil || err != nil {
		log.Printf("Error retrieving group %s for deletion. Continuing...", name)
		return
	}
	_, err = client.Groups.DeleteGroup(group.ID)
	if err != nil {
		log.Fatal(err)
	}
	return
}

func GetGroup(client *gitlab.Client, gid interface{}) (*gitlab.Group, error) {
	group, _, err := client.Groups.GetGroup(gid)
	if err != nil {
		return nil, err
	}
	return group, nil
}

func CreateProject(client *gitlab.Client, name string, namespaceId int) *gitlab.Project {
	log.Printf("Creating project: %s", name)
	p := &gitlab.CreateProjectOptions{
		Name:                 gitlab.String(name),
		NamespaceID:          gitlab.Int(namespaceId),
		Description:          gitlab.String("Just a test project to play with"),
		MergeRequestsEnabled: gitlab.Bool(true),
		SnippetsEnabled:      gitlab.Bool(true),
		Visibility:           gitlab.Visibility(gitlab.InternalVisibility),
	}
	project, _, err := client.Projects.CreateProject(p)
	if err != nil {
		log.Fatal(err)
	}
	return project
}

func GetProject(client *gitlab.Client, pid interface{}) *gitlab.Project {
	gp := &gitlab.GetProjectOptions{}

	project, _, err := client.Projects.GetProject(pid, gp)
	if err != nil {
		log.Fatalf("Unable to read ACM project info from GitLab: %v", err)
	}
	return project
}

func CreateBranch(client *gitlab.Client, pid interface{}, branch string, ref string) {
	cb := &gitlab.CreateBranchOptions{
		Branch: gitlab.String("staging"),
		Ref:    gitlab.String("master"),
	}
	_, _, err := client.Branches.CreateBranch(pid, cb)
	if err != nil {
		log.Fatalf("Unable to create staging branch for -env repo: %v", err)
	}
}

func AddDeployKey(client *gitlab.Client, pid interface{}, path string, title string, canPush bool) {
	project := GetProject(client, pid)
	log.Debugf("Adding deploy key (%v) to project: %v", title, project.Name)
	publicKey, err := ioutil.ReadFile(path)
	if err != nil {
		log.Fatal("Unable to read public key: " + path)
	}
	dk := &gitlab.AddDeployKeyOptions{
		Title:   gitlab.String(title),
		Key:     gitlab.String(string(publicKey)),
		CanPush: gitlab.Bool(canPush),
	}
	_, _, err = client.DeployKeys.AddDeployKey(pid, dk)
	if err != nil {
		log.Fatal("Unable to add deploy key to project %v: %v", pid, err)
	}
}

func DeleteDeployKey(client *gitlab.Client, pid interface{}, title string) {
	project := GetProject(client, pid)
	log.Debugf("Deleting deploy key from project: %v", project.Name)
	deployKeys, _, err := client.DeployKeys.ListProjectDeployKeys(pid, &gitlab.ListProjectDeployKeysOptions{PerPage: 100})
	if err != nil {
		log.Fatalf("Unable to list deploy keys for project %v: %v", pid, err)
	}

	keyID := -1
	for _, key := range deployKeys {
		if key.Title == title {
			keyID = key.ID
			break
		}
	}
	if keyID == -1 {
		log.Fatalf("Unable to find public key titled: %v", string(title))
	} else {
		resp, err := client.DeployKeys.DeleteDeployKey(pid, keyID)
		if err != nil {
			log.Fatalf("Unable to delete deploy key from project %v: (%v) %v", pid, resp.StatusCode, err)
		}
	}
}

func CopyProject(client *gitlab.Client, sshKeyPath string, sourceNamespace string, sourceName string, destNamespace string, destName string, mutateRepo ...func(*git.Worktree) *git.Worktree) *gitlab.Project {
	destURL := "git@" + client.BaseURL().Hostname() + ":" + destNamespace + "/" + destName
	log.Printf("Copying project %s/%s to %s/%s", sourceNamespace, sourceName, destNamespace, destName)
	log.Debugf("Using remote: %s", destURL)

	g, _, err := client.Groups.GetGroup(destNamespace)
	if err != nil {
		log.Fatalf("Unable to find group (%s): %v", destNamespace, err)
	}

	// Crete the new project
	project := CreateProject(client, destName, g.ID)

	// Add deploy key to source project so that we can clone it
	sourceRepo := GetProject(client, fmt.Sprintf("%s/%s", sourceNamespace, sourceName))
	keyTitle := fmt.Sprintf("Anthos Platform CLI Cloning to Repo: %s", project.Name)
	AddDeployKey(client, sourceRepo.ID, sshKeyPath+".pub", keyTitle, false)

	r := CloneRepo(client, sourceNamespace, sourceName, sshKeyPath)
	DeleteDeployKey(client, sourceRepo.ID, keyTitle)

	err = r.DeleteRemote("origin")
	if err != nil {
		log.Fatalf("Unable to delete remote: %v", err)
	}

	c := &config.RemoteConfig{Name: "origin", URLs: []string{destURL}}
	_, err = r.CreateRemote(c)
	if err != nil {
		log.Fatalf("Unable to create remote: %v", err)
	}

	// Make any necessary tweaks to the repo
	worktree, err := r.Worktree()
	if err != nil {
		log.Fatalf("Unable to get worktree when cloning repo: %s", err)
	}
	for _, mutation := range mutateRepo {
		worktree = mutation(worktree)
	}

	deployKeyName := fmt.Sprintf("Copying %s to %s", sourceName, destName)
	AddDeployKey(client, project.ID, sshKeyPath+".pub", deployKeyName, true)
	defer DeleteDeployKey(client, project.ID, deployKeyName)
	err = r.Push(&git.PushOptions{Auth: GetSSHAuth(sshKeyPath)})
	if err != nil {
		log.Fatalf("Unable to push commit: %v", err)
	}
	return project
}

// AddVariable adds a variable to a project for use in CI
func AddVariable(client *gitlab.Client, pid interface{}, key string, value string, protected bool) {
	project := GetProject(client, pid)
	log.Printf("Adding variable %v to %v", key, project.Name)
	v := &gitlab.CreateProjectVariableOptions{
		Key:       gitlab.String(key),
		Value:     gitlab.String(value),
		Protected: gitlab.Bool(protected),
	}
	_, _, err := client.ProjectVariables.CreateVariable(pid, v)
	if err != nil {
		log.Fatal("Unable to add variable to project " + pid.(string) + ": " + key)
	}
}

// ForkProject forks a project in GitLab
func ForkProject(client *gitlab.Client, name string, namespace string, templateName string) *gitlab.Project {
	gp := &gitlab.GetProjectOptions{}
	templateProject, _, err := client.Projects.GetProject(templateName, gp)
	if err != nil {
		log.Fatal("Unable to get project: " + templateName)
	}
	fp := &gitlab.ForkProjectOptions{
		Namespace: gitlab.String(namespace),
		Name:      gitlab.String(name),
		Path:      gitlab.String(name),
	}
	project, _, err := client.Projects.ForkProject(templateProject.ID, fp)
	if err != nil {
		log.Fatalf("Unable to fork project: %v", err)
	}
	return project
}

// FixRunnerTagsInEnvTemplate ensures the -env project has the correct tags set from its runners to be able to deploy
func FixRunnerTagsInEnvTemplate(client *gitlab.Client, name string, sshKeyPath string) {
	log.Printf("Fixing runner tags for %s", name)
	envRepoName := name + "-env"
	envRepoPid := name + "/" + envRepoName

	// Add deploy key to source project so that we can clone it
	sourceRepo := GetProject(client, fmt.Sprintf("%s/%s", name, envRepoName))
	keyTitle := fmt.Sprintf("Anthos Platform CLI Cloning: %s", name)
	AddDeployKey(client, sourceRepo.ID, sshKeyPath+".pub", keyTitle, false)

	// Clone ACM repo
	r := CloneRepo(client, name, envRepoName, sshKeyPath)
	DeleteDeployKey(client, sourceRepo.ID, keyTitle)

	// Get a worktree so we can operate on the files
	w, err := r.Worktree()
	if err != nil {
		log.Fatalf("Unable to read worktree from respository: %v", err)
	}
	gitlabCIFileName := ".gitlab-ci.yml"
	in, err := w.Filesystem.OpenFile(gitlabCIFileName, os.O_RDWR, os.ModePerm)
	if err != nil {
		log.Fatalf("Unable to open file %v: %v", gitlabCIFileName, err)
	}

	inBytes, err := ioutil.ReadAll(in)
	defer in.Close()
	if err != nil {
		log.Fatalf("Unable to read file %v: %v", gitlabCIFileName, err)
	}
	in.Truncate(0)
	in.Seek(0, 0)

	// Replace APP_NAME with the name of the new app
	outString := strings.ReplaceAll(string(inBytes), "APP_NAME", name)
	_, err = in.Write([]byte(outString))
	if err != nil {
		log.Fatalf("Unable to write to file %v: %v", inBytes, err)
	}

	// Stage the new file in the index
	w.Add(gitlabCIFileName)

	_, err = w.Commit("Fix labels in CI", &git.CommitOptions{
		Author: &object.Signature{
			Name:  "Anthos Platform CLI",
			Email: "apctl@" + client.BaseURL().Hostname(),
			When:  time.Now(),
		},
	})
	if err != nil {
		log.Fatalf("Unable to commit: %v", err)
	}

	// Set up authentication for this push, then tear it down
	deployKeyName := fmt.Sprintf("Adding %s to ACM repo", name)
	AddDeployKey(client, envRepoPid, sshKeyPath+".pub", deployKeyName, true)
	defer DeleteDeployKey(client, envRepoPid, deployKeyName)

	err = r.Push(&git.PushOptions{Auth: GetSSHAuth(sshKeyPath)})
	if err != nil {
		log.Fatalf("Unable to push commit: %v", err)
	}
}

func CloneRepo(client *gitlab.Client, repoNamespace string, repoName string, sshKeyPath string) *git.Repository {
	// Clone the repo into memory
	repoURL := fmt.Sprintf("git@%s:%s/%s.git", client.BaseURL().Hostname(), repoNamespace, repoName)
	fs := memfs.New()
	r, err := git.Clone(memory.NewStorage(), fs, &git.CloneOptions{
		URL:  repoURL,
		Auth: GetSSHAuth(sshKeyPath),
	})
	if err != nil {
		log.Fatalf("Unable to clone ACM respoitory %v: %v", repoURL, err)
	}
	return r
}

func GetSSHAuth(sshKeyPath string) *ssh2.PublicKeys {
	// Set up the private key so we can use it to authenticate for an SSH clone
	pem, err := ioutil.ReadFile(sshKeyPath)
	if err != nil {
		log.Fatal("Unable to read SSH Private key file for cloning")
	}
	signer, _ := ssh.ParsePrivateKey(pem)
	// TODO check for host key
	callback := func(hostname string, remote net.Addr, key ssh.PublicKey) error { return nil } //, err := ssh2.NewKnownHostsCallback()
	callbackHelper := ssh2.HostKeyCallbackHelper{HostKeyCallback: callback}
	sshAuth := &ssh2.PublicKeys{User: "git", Signer: signer, HostKeyCallbackHelper: callbackHelper}
	return sshAuth
}
