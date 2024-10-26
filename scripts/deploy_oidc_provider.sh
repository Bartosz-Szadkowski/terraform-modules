#!/bin/bash

# Set variables
OIDC_PROVIDER_URL="https://token.actions.githubusercontent.com"
OIDC_AUDIENCE="sts.amazonaws.com"

# Generate a unique name for the OIDC provider
OIDC_PROVIDER_NAME="GitHubOIDCProvider-$(date +%Y%m%d%H%M%S)"

# Function to check if OIDC provider already exists
function check_oidc_provider_exists {
  aws iam list-open-id-connect-providers | grep "$OIDC_PROVIDER_URL"
}

# Function to create OIDC provider
function create_oidc_provider {
  aws iam create-open-id-connect-provider \
    --url "$OIDC_PROVIDER_URL" \
    --client-id-list "$OIDC_AUDIENCE" \
    --thumbprint-list "A031C46782E6E6C662C2C87C76DA9AA62CCABD8E" \
    --query "OpenIDConnectProviderArn" \
    --output text
}

# Main logic
echo "Checking if OIDC provider for GitHub Actions already exists..."

if check_oidc_provider_exists; then
  echo "OIDC provider already exists."
else
  echo "Creating OIDC provider for GitHub Actions..."
  OIDC_PROVIDER_ARN=$(create_oidc_provider)
  
  if [ -n "$OIDC_PROVIDER_ARN" ]; then
    echo "OIDC provider created successfully!"
    echo "OIDC Provider ARN: $OIDC_PROVIDER_ARN"
  else
    echo "Failed to create OIDC provider."
    exit 1
  fi
fi

echo "OIDC provider configuration completed."
