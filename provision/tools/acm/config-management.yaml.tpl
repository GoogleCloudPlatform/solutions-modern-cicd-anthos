apiVersion: configmanagement.gke.io/v1
kind: ConfigManagement
metadata:
  name: config-management
spec:
  # clusterName is required and must be unique among all managed clusters
  clusterName: ${CONTEXT}
  policyController:
    enabled: true
  git:
    syncRepo: git@${GITLAB_HOSTNAME}:platform-admins/anthos-config-management.git
    syncBranch: master
    secretType: ssh
