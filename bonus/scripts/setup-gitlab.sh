#!/bin/bash

log_info() {
    echo -e "\033[1;34mINFO:\033[0m $1"
}

log_success() {
    echo -e "\033[1;32mSUCCESS:\033[0m $1"
}

log_error() {
    echo -e "\033[1;31mERROR:\033[0m $1"
    exit 1
}

install_helm()
{
    if ! command -v helm >/dev/null 2>&1; then   
        curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
        sudo apt-get install apt-transport-https --yes
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
        sudo apt-get update
        sudo apt-get install helm
    else
        log_success "Helm is already installed."
    fi
}

install_gitlab()
{
    kubectl create namespace gitlab

    helm repo add gitlab https://charts.gitlab.io/
    helm repo update
    helm upgrade --install gitlab gitlab/gitlab \
    --timeout 600s \
    --set global.edition=ce \
    --set global.hosts.domain=example.com \
    --set global.hosts.externalIP=192.168.56.110 \
    --set certmanager-issuer.email=me@example.com \
    --version 8.5.2 \
    --namespace gitlab
}

main()
{
    install_helm
    install_gitlab
}

main