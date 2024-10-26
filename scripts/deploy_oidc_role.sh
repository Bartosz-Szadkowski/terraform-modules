#!/bin/bash

# Set variables
ROLE_NAME="GitHubActionsRoleEsta"
ROLE_DESCRIPTION="Role for GitHub Actions workflows."
POLICY_NAME="GitHubActionsPolicy"
REPO_NAME="Bartosz-Szadkowski/aws-eks-infra-v2"
OIDC_PROVIDER_URL="token.actions.githubusercontent.com"

# Fetch AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

# Construct OIDC provider ARN
OIDC_PROVIDER_ARN="arn:aws:iam::$ACCOUNT_ID:oidc-provider/$OIDC_PROVIDER_URL"

# IAM Role Trust Policy JSON
TRUST_POLICY=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Principal": {
                "Federated": "$OIDC_PROVIDER_ARN"
            },
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:$REPO_NAME:*"
                }
            }
        }
    ]
}
EOF
)

# Create IAM Role with the trust policy
echo "Creating IAM Role: $ROLE_NAME..."

aws iam create-role \
  --role-name "$ROLE_NAME" \
  --assume-role-policy-document "$TRUST_POLICY" \
  --description "$ROLE_DESCRIPTION"

if [ $? -eq 0 ]; then
    echo "IAM Role $ROLE_NAME created successfully!"
else
    echo "Failed to create IAM Role."
    exit 1
fi

# Attach the necessary policies (optional, attach custom policies as needed)
echo "Attaching policies to IAM Role $ROLE_NAME..."

# Replace with your specific policies
POLICY_ARN="arn:aws:iam::aws:policy/AdministratorAccess"

aws iam attach-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-arn "$POLICY_ARN"

if [ $? -eq 0 ]; then
    echo "Policy $POLICY_ARN attached successfully to $ROLE_NAME!"
else
    echo "Failed to attach policy to $ROLE_NAME."
    exit 1
fi

echo "IAM Role $ROLE_NAME configuration completed."
