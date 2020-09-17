#!/bin/bash

# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

artifact_registry_location=us-central1
project=$(gcloud config get-value core/project)
readonly project_var_name_gcp_ar_repo=GCP_AR_REPO
readonly project_var_name_gcp_ar_key=GCP_AR_KEY

usage () {
    echo "usage: ./ar-setup.sh --app-name <app_name> --gitlab-access-token <token> --app-config-repo <app-config-repo> [--project <gcp_project>] [--artifact-registry-location <location>]"
	echo "  OR   ./ar-setup.sh --app-name=<app_name> --gitlab-access-token=<token> --app-config-repo=<app-config-repo> [--project=<gcp_project>] [--artifact-registry-location=<location>]"
	echo "  --app-name (required): the application name."
	echo "  --app-config-repo (required): the URL to the application project. This is needed so that we can add the AR repository and the Google service account key as project variables of the application project."
	echo "  --gitlab-access-token (required): the GitLab personal access token for accessing the GitLab APIs. If you don't have one, see https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html for how to create personal access tokens with 'api' scope."
	echo "  --project (optional): the GCP project ID. If not specified, using the output of \`gcloud config get-value core/project\`."
	echo "  --artifact-registry-location (optional): the artifact registry location (default to us-central1)."
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
		--app-name) shift; app_name="$1" ;;
		--app-name=*) app_name="${1#*=}" ;;
		--project) shift; project="$1" ;;
		--project=*) project="${1#*=}" ;;
		--artifact-registry-location) shift; artifact_registry_location="$1" ;;
		--artifact-registry-location=*) artifact_registry_location="${1#*=}" ;;
		--app-config-repo) shift; app_config_repo="$1" ;;
		--app-config-repo=*) app_config_repo="${1#*=}" ;;
		--gitlab-access-token) shift; gitlab_access_token="$1" ;;
		--gitlab-access-token=*) gitlab_access_token="${1#*=}" ;;
		*) echo "Unknown parameter passed: $1"; usage; exit 1 ;;
    esac
    shift
done

if [ -z "${app_name}" ] || [ -z "${app-config-repo}" ] || [ -z "${gitlab_access_token}" ]; then
	usage
	exit 1
fi

# check whether the artifact repository already exists, and create the repository if it does not exist
gcloud beta artifacts repositories describe "${app_name}" --location="${artifact_registry_location}" >/dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "The artifact repository \"${app_name}\" does not exist"
	gcloud beta artifacts repositories create "${app_name}" --location="${artifact_registry_location}" --repository-format=docker >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "Failed to create the artifact repository \"${app_name}\" at the location ${artifact_registry_location}"
		exit 1
	else 
		echo "Created the artifact repository \"${app_name}\" at the location ${artifact_registry_location}"
	fi
else
	echo "The artifact repository \"${app_name}\" already exists"
fi

# check whether the service account already exists, and create the service account if it does not exist
service_account_name="${app_name}-push"
service_account_email="${service_account_name}@${project}.iam.gserviceaccount.com"
gcloud iam service-accounts describe "${service_account_email}" >/dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "The service account ${service_account_email} does not exist"
	service_account_description="Service Account for accessing the artifact repository \"${app_name}\""
	gcloud iam service-accounts create "${service_account_name}" --description "${service_account_description}" >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "Failed to create the service account ${service_account_email}"
		exit 1
	else
		echo "Created the service account ${service_account_email}"
	fi
else
	echo "The service account ${service_account_email} already exists"
fi

# grant the Google service account roles/artifactregistry.writer on the AR repo (this command is idempotent)
gcloud beta artifacts repositories add-iam-policy-binding "${app_name}" \
	--location="${artifact_registry_location}" \
	--member=serviceAccount:"${service_account_email}" \
	--role=roles/artifactregistry.writer >/dev/null
if [ $? -ne 0 ]; then
	echo "Failed to grant the service account ${service_account_email} \"roles/artifactregistry.writer\" on the artifact repository \"${app_name}\""
	exit 1
else
	echo "Granted the service account ${service_account_email} \"roles/artifactregistry.writer\" on the artifact repository \"${app_name}\""
fi

check_gitlab_api_access_permission() {
	cmd_output=$1
	unauthorized_msg="401 Unauthorized"
	insufficient_scope_msg="insufficient_scope"
	if [[ "${cmd_output}" = *"${unauthorized_msg}"* ]] || [[ "${cmd_output}" = *"${insufficient_scope_msg}"* ]]; then
		echo "Your personal access token does not has sufficent scope to access GitLab APIs. Please make sure your token has \`api\` scope: https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html#limiting-scopes-of-a-personal-access-token"
		exit 1
	fi
}

add_gitlab_project_vars() {
	# get the gitlab hostname and gitlab project name from app_config_repo
	https_prefix="https://"
	https_prefix_len=${#https_prefix}
	app_config_repo_without_https_prefix=${app_config_repo:https_prefix_len}

	end_of_gitlab_hostname_index=$(expr index ${app_config_repo_without_https_prefix} /)
	gitlab_hostname_len=https_prefix_len+end_of_gitlab_hostname_index
	gitlab_hostname=${app_config_repo:0:gitlab_hostname_len}

	gitlab_project=${app_config_repo:gitlab_hostname_len}
	# replace the slash in the project name with %2F
	gitlab_project=${gitlab_project//\//%2F}

	# check whether the GitLab project exists
	output_project_existence=$(curl -s --header "PRIVATE-TOKEN: ${gitlab_access_token}" "${gitlab_hostname}api/v4/projects/${gitlab_project}")
	check_gitlab_api_access_permission "${output_project_existence}"

	not_found_msg="Not Found"
	if [[ "${output_project_existence}" = *"${not_found_msg}"* ]]; then
		echo "The GitLab project \"${app_config_repo}\" does not exist. Please run \`appctl init\` to create the project first."
		exit 1
	fi

	# add the AR repo and the service account key into the app project as GitLab project variables
	output_repo=$(curl -s --header "PRIVATE-TOKEN: ${gitlab_access_token}" "${gitlab_hostname}api/v4/projects/${gitlab_project}/variables/${project_var_name_gcp_ar_repo}")
	output_key=$(curl -s --header "PRIVATE-TOKEN: ${gitlab_access_token}" "${gitlab_hostname}api/v4/projects/${gitlab_project}/variables/${project_var_name_gcp_ar_key}")
	
	if [[ "${output_repo}" = *"${not_found_msg}"* ]] && [[ "${output_key}" = *"${not_found_msg}"* ]]; then
		# create and download a service account key
		# For each service account, only 12 keys can be created. So we only create the key when all the preconditions are met.
		key_file=$(mktemp)
		gcloud iam service-accounts keys create --iam-account="${service_account_email}" "${key_file}"
		if [ $? -ne 0 ]; then
			echo "Failed to download a service account key for ${service_account_email}"
			exit 1
		fi
		service_account_key=$(cat "${key_file}")
		rm -f "${key_file}"
		artifact_repo_name="${artifact_registry_location}-docker.pkg.dev/${project}/${app_name}"

		output=$(curl -s --request POST --header "PRIVATE-TOKEN: ${gitlab_access_token}" "${gitlab_hostname}api/v4/projects/${gitlab_project}/variables" --form "key=${project_var_name_gcp_ar_repo}" --form "value=${artifact_repo_name}")
		check_gitlab_api_access_permission "${output}"
		curl -s --request POST --header "PRIVATE-TOKEN: ${gitlab_access_token}" "${gitlab_hostname}api/v4/projects/${gitlab_project}/variables" --form "key=${project_var_name_gcp_ar_key}" --form "value=${service_account_key}" >/dev/null
	else
		echo "${app_config_repo} already includes project variables ${project_var_name_gcp_ar_repo} and/or ${project_var_name_gcp_ar_key}, please delete them first."
		exit 1
	fi
}

add_gitlab_project_vars
if [ $? -ne 0 ]; then
	echo "Failed to add the artifact repository and the service account key into the app project as GitLab project variables"
	exit 1
else
	echo "Added the artifact repository and the service account key into the app project as GitLab project variables"
fi