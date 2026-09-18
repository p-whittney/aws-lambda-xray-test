# Lambda X-Ray Test

## Aim

Deploy and test a python AWS Lambda with AWS X-Ray enabled to test finding issues in AWS server-less sceanareos

## Requirements

- AWS Build via IaC
  - Cloudformation
  - Terraform  
- Github Workflow to deploy lambda changes on PR update

## Resources

- DynomoDB
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

