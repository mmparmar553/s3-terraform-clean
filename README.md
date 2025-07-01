# S3 Bucket Terraform with GitHub Actions

This project creates an AWS S3 bucket using Terraform and deploys it via GitHub Actions.

## Features

- **S3 Bucket**: Secure S3 bucket with encryption, versioning, and lifecycle policies
- **Security**: Public access blocked by default
- **Lifecycle Management**: Automatic transition to IA and Glacier storage classes
- **GitHub Actions**: Automated deployment pipeline
- **Environment Management**: Separate configurations for dev/prod

## Prerequisites

1. AWS Account with appropriate permissions
2. GitHub repository
3. GitHub Secrets configured

## Quick Setup

1. **Configure GitHub Secrets** (Repository Settings → Secrets and variables → Actions):
   - `AWS_ACCESS_KEY_ID`: Your AWS access key
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
   - `S3_BUCKET_NAME`: Your unique S3 bucket name

2. **Local Development**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   terraform init
   terraform plan
   ```

## Workflow

- **Pull Requests**: Runs `terraform plan` to show changes
- **Push to main**: Automatically applies changes to production
- **Push to develop**: Runs plan for development environment

## Security Best Practices

✅ **Implemented:**
- S3 bucket encryption enabled
- Public access blocked
- Versioning enabled
- Lifecycle policies configured
- IAM permissions follow least privilege
- Secrets stored in GitHub Secrets

## File Structure

```
.
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output definitions
├── terraform.tfvars.example   # Example variables file
├── iam-policy.json           # IAM policy for GitHub Actions
├── .github/
│   └── workflows/
│       └── terraform.yml      # GitHub Actions workflow
└── README.md                  # This file
```

## AWS IAM Setup

Create an IAM user with the policy defined in `iam-policy.json` and use the access keys in GitHub Secrets.

## Troubleshooting

### Common Issues

1. **Bucket name already exists**: S3 bucket names must be globally unique
2. **Permission denied**: Check IAM permissions and AWS credentials
3. **Terraform state**: Consider using remote state for production
