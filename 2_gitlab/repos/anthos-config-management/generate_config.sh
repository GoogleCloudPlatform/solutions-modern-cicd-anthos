#!/bin/sh

server=https://${KUBERNETES_PORT_443_TCP_ADDR}:${KUBERNETES_SERVICE_PORT_HTTPS}
ca=$(cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt | base64 | tr -d '\n')
token=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
namespace=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)

echo "
apiVersion: v1
kind: Config
clusters:
- name: default-cluster
  cluster:
    certificate-authority-data: ${ca}
    server: ${server}
contexts:
- name: default-context
  context:
    cluster: default-cluster
    namespace: ${namespace}
    user: default-${namespace}
current-context: default-context
users:
- name: default-${namespace}
  user:
    token: ${token}
" > $(pwd)/${KUBECONFIG}