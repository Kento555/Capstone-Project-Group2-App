#!/bin/bash

# Input: environment (dev, staging, prod)
ENVIRONMENT=$1
CLUSTER_NAME="ce-grp-2-eks-cluster-$ENVIRONMENT"
AWS_REGION="us-east-1"

if [ -z "$ENVIRONMENT" ]; then
  echo "No environment specified. Usage: ./init.sh [dev|staging|prod]"
  exit 1
fi

echo "Updating kubeconfig for EKS cluster: $CLUSTER_NAME in region: $AWS_REGION"
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

echo "Creating namespace argocd if not exists..."
kubectl get namespace argocd || kubectl create namespace argocd

echo "Installing ArgoCD core components..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for ArgoCD pods to become ready..."
kubectl rollout status deployment argocd-server -n argocd
kubectl rollout status deployment argocd-repo-server -n argocd
kubectl rollout status deployment argocd-application-controller -n argocd
kubectl rollout status deployment argocd-dex-server -n argocd

# Apply the ArgoCD project and environment-specific application manifests
echo "Applying ArgoCD project manifest..."
kubectl apply -f ./argocd/bootstrap/repository.yaml
kubectl apply -f ./argocd/bootstrap/appofapps-project.yaml
kubectl apply -f ./argocd/bootstrap/appofapps-application.yaml

# Check for environment-specific application file
APP_MANIFEST="./argocd/bootstrap/${ENVIRONMENT}/appofapps.yaml"

if [ -f "$APP_MANIFEST" ]; then
  echo "Applying ArgoCD AppOfApps manifest for environment: $ENVIRONMENT"
  kubectl apply -f "$APP_MANIFEST"
else
  echo "AppOfApps manifest for environment $ENVIRONMENT not found. Applying default application manifest."
  kubectl apply -f ./argocd/bootstrap/appofapps-application.yaml
fi

echo "ArgoCD setup complete for environment: $ENVIRONMENT"
