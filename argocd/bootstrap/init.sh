#!/bin/bash

# Input: environment (dev, staging, prod)
ENVIRONMENT=${GITHUB_ENVIRONMENT:-$1}
CLUSTER_NAME="ce-grp-2-eks-cluster-$ENVIRONMENT"
AWS_REGION="us-east-1"

if [ -z "$ENVIRONMENT" ]; then
  echo "No environment specified. Usage: ./init.sh [dev|uat|prod]"
  exit 1
fi

echo "Updating kubeconfig for EKS cluster: $CLUSTER_NAME in region: $AWS_REGION"
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

echo "Creating namespace argocd if not exists..."
kubectl get namespace argocd || kubectl create namespace argocd

# Check if ArgoCD is already installed by looking for argocd-server deployment
if kubectl get deployment argocd-server -n argocd &>/dev/null; then
  echo "ArgoCD is already installed. Skipping installation..."
else
  echo "Installing ArgoCD core components..."
  kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

  echo "Waiting for ArgoCD pods to be ready..."
  kubectl rollout status deployment argocd-server -n argocd
  kubectl rollout status deployment argocd-repo-server -n argocd
  kubectl rollout status deployment argocd-application-controller -n argocd
  kubectl rollout status deployment argocd-dex-server -n argocd
fi

# Apply the environment-specific bootstrap YAMLs
BOOTSTRAP_DIR="./argocd/bootstrap/${ENVIRONMENT}"

if [ -d "$BOOTSTRAP_DIR" ]; then
  echo "Applying bootstrap manifests for environment: $ENVIRONMENT"

  for yaml_file in "$BOOTSTRAP_DIR"/*.yaml; do
    echo "📄 Applying $yaml_file"
    kubectl apply -f "$yaml_file"
  done
else
  echo "Bootstrap directory for $ENVIRONMENT not found: $BOOTSTRAP_DIR"
  exit 1
fi
fi

echo "ArgoCD setup complete for environment: $ENVIRONMENT"
