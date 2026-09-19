S3=pwhittney-deployment-aadg6yri
PYTHON_APP_VERSION=v1.0
PYTHON_APP_PATH=lambda/code/dog-activities
LAYER_VERSION=v1.0
LAYER_PATH=lambda/layers/aws-xray-sdk
PYTHON_VERSION=3.13
VENV_DIR=.venv
LAYER_DIR=layers/aws-xray-sdk
EMAIL=user@example.com
TIMESTAMP=$(shell date +%Y%m%d-%H%M%S)
CHANGESET_NAME=update-$(TIMESTAMP)
ALLOWED_BRANCH ?= *

-include Makefile.env

# Cloudformation targets for : setup (needed before lambda)

create-cf-deploy-setup:
	aws cloudformation deploy \
		--template-file cloudformation/setup.yaml \
		--stack-name dog-activities-setup \
		--parameter-overrides NotificationEmail=${EMAIL} \
		--capabilities CAPABILITY_IAM

update-cf-setup:
	aws cloudformation create-change-set \
		--stack-name dog-activities-setup \
		--template-body file://cloudformation/setup.yaml \
		--parameters ParameterKey=NotificationEmail,ParameterValue=${EMAIL} \
		--capabilities CAPABILITY_IAM \
		--change-set-name $(CHANGESET_NAME)

review-cf-setup:
	@aws cloudformation list-change-sets --stack-name dog-activities-setup --query 'Summaries[0].ChangeSetName' --output text | \
	xargs -I {} aws cloudformation describe-change-set \
		--stack-name dog-activities-setup \
		--change-set-name {} \
		--query 'Changes[*].[ResourceChange.Action, ResourceChange.LogicalResourceId, ResourceChange.ResourceType, ResourceChange.Replacement]' \
		--output table

execute-cf-setup:
	@aws cloudformation list-change-sets --stack-name dog-activities-setup --query 'Summaries[0].ChangeSetName' --output text | \
	xargs -I {} aws cloudformation execute-change-set \
		--stack-name dog-activities-setup \
		--change-set-name {}
	aws cloudformation wait stack-update-complete --stack-name dog-activities-setup

show-cf-deploy-setup:
	aws cloudformation list-exports \
    	--query "Exports[?contains(ExportingStackId, 'dog-activities-setup')].{Name:Name, Value:Value}"

# Cloudformation targets for : lambda

create-cf-deploy-lambda:
	aws cloudformation deploy \
		--template-file cloudformation/lambda.yaml \
		--stack-name dog-activities-lambda \
		--parameter-overrides SetupStackName=dog-activities-setup

update-cf-lambda:
	aws cloudformation create-change-set \
		--stack-name dog-activities-lambda \
		--template-body file://cloudformation/lambda.yaml \
		--parameters ParameterKey=SetupStackName,ParameterValue=dog-activities-setup \
		--change-set-name $(CHANGESET_NAME)

review-cf-lambda:
	@aws cloudformation list-change-sets --stack-name dog-activities-lambda --query 'Summaries[0].ChangeSetName' --output text | \
	xargs -I {} aws cloudformation describe-change-set \
		--stack-name dog-activities-lambda \
		--change-set-name {} \
		--query 'Changes[*].[ResourceChange.Action, ResourceChange.LogicalResourceId, ResourceChange.ResourceType, ResourceChange.Replacement]' \
		--output table

execute-cf-lambda:
	@aws cloudformation list-change-sets --stack-name dog-activities-lambda --query 'Summaries[0].ChangeSetName' --output text | \
	xargs -I {} aws cloudformation execute-change-set \
		--stack-name dog-activities-lambda \
		--change-set-name {}
	aws cloudformation wait stack-update-complete --stack-name dog-activities-lambda

# Cloudformation targets for : oidc

create-cf-deploy-oidc:
	aws cloudformation deploy \
		--template-file cloudformation/oidc.yaml \
		--stack-name dog-activities-oidc \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameter-overrides \
			GitHubOrg=${GITHUB_ORG} \
			GitHubRepo=${GITHUB_REPO} \
			AllowedBranch="${ALLOWED_BRANCH}" \
			DeploymentBucket=${S3}

update-cf-oidc:
	aws cloudformation create-change-set \
		--stack-name dog-activities-oidc \
		--template-body file://cloudformation/oidc.yaml \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameters \
			ParameterKey=GitHubOrg,ParameterValue=${GITHUB_ORG} \
			ParameterKey=GitHubRepo,ParameterValue=${GITHUB_REPO} \
			ParameterKey=DeploymentBucket,ParameterValue=${S3} \
			ParameterKey=AllowedBranch,ParameterValue=${ALLOWED_BRANCH} \
		--change-set-name $(CHANGESET_NAME)

review-cf-oidc:
	@aws cloudformation list-change-sets --stack-name dog-activities-oidc --query 'Summaries[0].ChangeSetName' --output text | \
	xargs -I {} aws cloudformation describe-change-set \
		--stack-name dog-activities-oidc \
		--change-set-name {} \
		--query 'Changes[*].[ResourceChange.Action, ResourceChange.LogicalResourceId, ResourceChange.ResourceType, ResourceChange.Replacement]' \
		--output table

execute-cf-oidc:
	@aws cloudformation list-change-sets --stack-name dog-activities-oidc --query 'Summaries[0].ChangeSetName' --output text | \
	xargs -I {} aws cloudformation execute-change-set \
		--stack-name dog-activities-oidc \
		--change-set-name {}
	aws cloudformation wait stack-update-complete --stack-name dog-activities-oidc

# Python Code build and deploys

.venv:
	uv venv --python "${PYTHON_VERSION}" "${VENV_DIR}"
	uv pip install \
		--python "${VENV_DIR}/bin/python" \
		boto3 \
		-r "${LAYER_DIR}/requirements.txt"

# Build the layer directory when requirements.txt changes
build/aws-xray-sdk/python: layers/aws-xray-sdk/requirements.txt .venv
	rm -rf build/aws-xray-sdk
	mkdir -p build/aws-xray-sdk/python
	uv pip install \
		--python "${VENV_DIR}/bin/python" \
		--target "$@" \
		-r layers/aws-xray-sdk/requirements.txt

build/aws-xray-sdk.zip: build/aws-xray-sdk/python
	(cd "build/aws-xray-sdk/" && zip -qr "../aws-xray-sdk.zip" python)

copy-lambda-layer: build/aws-xray-sdk.zip
	aws s3 cp build/aws-xray-sdk.zip \
		s3://${S3}/${LAYER_PATH}/${LAYER_VERSION}/aws-xray-sdk.zip

# Main python Lambda Code

build/dog-activities.zip: code/dog-activities/dogActivities.py
	(cd "code/dog-activities/" && zip -qr "../../build/dog-activities.zip" .)

copy-lambda-code: build/dog-activities.zip
	aws s3 cp build/dog-activities.zip \
		s3://${S3}/${PYTHON_APP_PATH}/${PYTHON_APP_VERSION}/dog-activities.zip
