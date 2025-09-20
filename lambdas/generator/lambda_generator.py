import boto3
import json
import uuid
from datetime import datetime
import os

def lambda_handler(event, context):
    # Modelo Claude 3 Sonnet funcional
    model_id = "anthropic.claude-3-sonnet-20240229-v1:0"

    prompt = (
        "You are an expert in leadership, team development, and motivational coaching. "
        "Write a brief, powerful, and unique phrase that inspires a technology development team to start their day with motivation."
    )


    bedrock = boto3.client("bedrock-runtime")

    body = {
        "anthropic_version": "bedrock-2023-05-31",
        "messages": [
            {
                "role": "user",
                "content": prompt
            }
        ],
        "max_tokens": 100,
        "temperature": 0.9,
        "top_p": 0.9
    }

    response = bedrock.invoke_model(
        modelId=model_id,
        contentType="application/json",
        accept="application/json",
        body=json.dumps(body)
    )

    payload = json.loads(response['body'].read())
    phrase = payload["content"][0]["text"].strip()

    # Guardar en DynamoDB
    dynamodb = boto3.resource("dynamodb")
    table_name = os.environ.get("DYNAMO_TABLE", "MotivationalQuotes")
    table = dynamodb.Table(table_name)

    table.put_item(Item={
        "id": str(uuid.uuid4()),
        "quote": phrase,
        "author": "kode-soul devops|cloud-arch Bedrock AI",
        "date": datetime.utcnow().isoformat()
    })

    return {
        "statusCode": 200,
        "body": json.dumps({"quote": phrase})
    }
