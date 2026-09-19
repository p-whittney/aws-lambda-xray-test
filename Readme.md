# Lambda X-Ray Test

## Aim

Deploy and test a python AWS Lambda with AWS X-Ray enabled to test finding issues in AWS server-less scenarios

## Requirements

- AWS Build via IaC
  - Cloudformation
  - Terraform  
- Github Workflow to deploy lambda changes on PR update

## Resources

- DynamoDB
  - Basic table with Required primary and secondary key
- SNS attached to Email
- Python Lambda code 
  - Layer for AWS Xray package

## DynamoDB Table

- Name: DogActivities
- Partition Key: DogName
- Sorting Key: Date
- Additional Attributes:
  - ActivityType
  - Notes

## GitHub Secrets Setup

Required Secrets in Environment `main`

### AWS_DEPLOY_ROLE_ARN

Purpose: IAM role that GitHub Actions assumes via OIDC to deploy to AWS

```bash
aws cloudformation describe-stacks \
  --stack-name dog-activities-oidc \
  --query 'Stacks[0].Outputs[?OutputKey==`RoleArn`].OutputValue' \
  --output text
```

### S3_BUCKET

Purpose: S3 bucket where Lambda code and layers are stored

```bash
aws cloudformation describe-stacks \
  --stack-name dog-activities-setup \
  --query 'Stacks[0].Outputs[?OutputKey==`DeploymentBucket`].OutputValue' \
  --output text
```

## Local Variables Setup

Create a Makefile.env to store cloudformation values without adding to git

```bash
EMAIL=your.email@here.com
GITHUB_ORG=github-repo-org
GITHUB_REPO=github-repo-name
ALLOWED_BRANCH="*"
S3=some-bucket
```

