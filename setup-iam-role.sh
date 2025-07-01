#!/bin/bash

# Setup IAM Role for GitHub Actions - Better Security Practice
# This script replaces IAM User with IAM Role for GitHub Actions

set -e

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account ID: $AWS_ACCOUNT_ID"

# Get GitHub repository info
GITHUB_REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
echo "GitHub Repository: $GITHUB_REPO"

# Step 1: Create OIDC Identity Provider (if not exists)
echo "🔧 Setting up OIDC Identity Provider..."
if ! aws iam list-open-id-connect-providers --query 'OpenIDConnectProviderList[?contains(Arn, `token.actions.githubusercontent.com`)]' --output text | grep -q token.actions.githubusercontent.com; then
    aws iam create-open-id-connect-provider \
        --url https://token.actions.githubusercontent.com \
        --client-id-list sts.amazonaws.com \
        --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
    echo "✅ OIDC Provider created"
else
    echo "✅ OIDC Provider already exists"
fi

# Step 2: Create Trust Policy
echo "🔧 Creating trust policy..."
cat > github-trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:${GITHUB_REPO}:*"
                }
            }
        }
    ]
}
EOF

# Step 3: Create IAM Role
echo "🔧 Creating IAM Role..."
if aws iam get-role --role-name GitHubActions-S3-Role >/dev/null 2>&1; then
    echo "⚠️  Role exists, updating trust policy..."
    aws iam update-assume-role-policy \
        --role-name GitHubActions-S3-Role \
        --policy-document file://github-trust-policy.json
else
    aws iam create-role \
        --role-name GitHubActions-S3-Role \
        --assume-role-policy-document file://github-trust-policy.json \
        --description "Role for GitHub Actions to manage S3 buckets"
    echo "✅ IAM Role created"
fi

# Step 4: Create S3 Policy
echo "🔧 Creating S3 policy..."
cat > s3-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:CreateBucket",
                "s3:DeleteBucket",
                "s3:GetBucketLocation",
                "s3:GetBucketVersioning",
                "s3:GetBucketEncryption",
                "s3:PutBucketVersioning",
                "s3:PutBucketEncryption",
                "s3:PutBucketPublicAccessBlock",
                "s3:GetBucketPublicAccessBlock",
                "s3:ListBucket",
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListAllMyBuckets"
            ],
            "Resource": [
                "arn:aws:s3:::*",
                "arn:aws:s3:::*/*"
            ]
        }
    ]
}
EOF

# Step 5: Create and attach policy
echo "🔧 Creating and attaching policy..."
POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/GitHubActions-S3-Policy"

if aws iam get-policy --policy-arn "$POLICY_ARN" >/dev/null 2>&1; then
    echo "⚠️  Policy exists, creating new version..."
    aws iam create-policy-version \
        --policy-arn "$POLICY_ARN" \
        --policy-document file://s3-policy.json \
        --set-as-default
else
    aws iam create-policy \
        --policy-name GitHubActions-S3-Policy \
        --policy-document file://s3-policy.json \
        --description "S3 permissions for GitHub Actions"
    echo "✅ Policy created"
fi

# Attach policy to role
aws iam attach-role-policy \
    --role-name GitHubActions-S3-Role \
    --policy-arn "$POLICY_ARN"
echo "✅ Policy attached to role"

# Step 6: Update GitHub Secrets
echo "🔧 Updating GitHub secrets..."

# Remove old secrets if they exist
gh secret delete AWS_ACCESS_KEY_ID 2>/dev/null || true
gh secret delete AWS_SECRET_ACCESS_KEY 2>/dev/null || true

# Add new secret
echo "$AWS_ACCOUNT_ID" | gh secret set AWS_ACCOUNT_ID
echo "✅ GitHub secrets updated"

# Step 7: Display role ARN
ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/GitHubActions-S3-Role"
echo ""
echo "🎉 Setup Complete!"
echo "📋 Role ARN: $ROLE_ARN"
echo "📋 Repository: $GITHUB_REPO"
echo ""
echo "Next steps:"
echo "1. Update your GitHub Actions workflow to use the role"
echo "2. Test the deployment"
echo ""

# Cleanup temporary files
rm -f github-trust-policy.json s3-policy.json

echo "✅ Temporary files cleaned up"
