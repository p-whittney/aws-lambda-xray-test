S3=pwhittney-deployment-aadg6yrI
PYTHON_VERSION=v1.0
PYTHON_PATH=lambda/code/dog-activities
LAYER_VERSION=v1.0
PYTHON_PATH=lambda/layers/aws-xray-sdk

EMAIL=user@example.com

create-cf-deploy-setup:
	aws cloudformation deploy \
		--template-file cloudformation/setup.yaml \
		--stack-name dog-activities-setup \
		--parameter-overrides NotificationEmail=${EMAIL} \
		--capabilities CAPABILITY_IAM

show-cf-deploy-setup:
	aws cloudformation list-exports \
    	--query "Exports[?contains(ExportingStackId, 'dog-activities-setup')].{Name:Name, Value:Value}"

deploy-lambda-python:
	aws s3 cp build/dog-activities.zip \
		s3://${S3}/${PYTHON_PATH}/${PYTHON_VERSION}/dog-activities.zip

deploy-lambda-layer:
	aws s3 cp build/aws-xray-sdk-layer.zip \
		s3://${S3}/${LAYER_PATH}/${LAYER_VERSION}/aws-xray-sdk-layer.zip

create-cf-deploy-lambda:
	aws cloudformation deploy \
		--template-file cloudformation/lambda.yaml \
		--stack-name dog-activities-lambda \
		--parameter-overrides SetupStackName=dog-activities-setup
