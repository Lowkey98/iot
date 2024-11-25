#!/bin/bash

# Define text styles for bold and normal
BOLD=$(tput bold)
NORMAL=$(tput sgr0)

# Function to create resources
create_resources() {
    echo "Creating Kubernetes cluster and namespaces..."
    k3d cluster create tbd-cluster || { echo "Failed to create Kubernetes cluster"; exit 1; }

    kubectl create namespace argocd
    kubectl create namespace dev

    echo "Installing ArgoCD..."
    kubectl -n argocd apply -f \
        https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    sleep 40 # Allow time for ArgoCD to initialize

    echo "Applying custom ArgoCD configuration..."
    kubectl -n argocd apply -f ../confs/argocd-application.yaml
    sleep 15

    echo "Retrieving ArgoCD admin password..."
    kubectl -n argocd get secret argocd-initial-admin-secret \
        -o jsonpath="{.data.password}" | base64 -d > argo-pass.txt
    echo "Password saved to argo-pass.txt"

    echo "Starting port forwarding..."
    kubectl port-forward svc/wil-playground-service -n dev 8888:80 &
    kubectl port-forward svc/argocd-server -n argocd 8080:443 &

    echo "Resources successfully created!"
}

# Function to delete resources
delete_resources() {
    echo "Deleting Kubernetes namespaces..."
    kubectl delete namespace argocd
    kubectl delete namespace dev
    k3d cluster delete tbd-cluster

    echo "Cleaning up temporary files and processes..."
    rm -f argo-pass.txt
    pkill -f "kubectl port-forward" || echo "No port-forward processes to kill."

    echo "Resources successfully deleted!"
}

# Display usage instructions
show_usage() {
    echo "Usage:"
    echo " $0 ${BOLD}create${NORMAL} | ${BOLD}delete${NORMAL}"
}

# Main script logic
case $1 in
    create)
        create_resources
        ;;
    delete)
        delete_resources
        ;;
    *)
        echo "Invalid option!"
        show_usage
        exit 1
        ;;
esac