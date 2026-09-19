#!/usr/bin/python

import sys
import os
import json
import boto3

from datetime import datetime
from boto3.dynamodb.conditions import Key, Attr

from aws_xray_sdk.core import xray_recorder, patch_all

# enable xray

patch_all()

sns_client = boto3.client('sns')
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('DogActivities')


def lambda_handler(event, context):
    # query dynamodb
    items = query_dynamo("Charlotte")
    filtered_items=filter_items(items)

    publish_to_sns(filtered_items)
    return {
        'statusCode': 200,
        'body': json.dumps({
            'processed_items': len(filtered_items)
        })
    }

def query_dynamo(name: str) -> list:
    response = table.query(
        KeyConditionExpression=Key('DogName').eq(name)
    )
    return response['Items']

@xray_recorder.capture("filter_items")
def filter_items(items: list) -> list:
    result = []
    for item in items:
        if item["ActivityType"] == "WALK":
            result.append(item['Date'])
    return result

def publish_to_sns(items: list):
    sns_client.publish(
        TopicArn=SNS_TOPIC_ARN,
        Message=json.dumps({
            'items': items
        })
    )
