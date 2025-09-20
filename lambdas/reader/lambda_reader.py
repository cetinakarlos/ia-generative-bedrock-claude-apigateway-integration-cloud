import boto3
import random
import json
import os

def lambda_handler(event, context):
    table_name = os.environ.get("DYNAMO_TABLE", "MotivationalQuotes")
    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table(table_name)

    result = table.scan()
    items = result.get("Items", [])

    if not items:
        return {
            "statusCode": 404,
            "body": json.dumps({"message": "No hay frases disponibles."})
        }

    phrase = random.choice(items)

    return {
        "statusCode": 200,
        "body": json.dumps({
            "quote": phrase.get("quote"),
            "author": phrase.get("author", "Anon"),
            "date": phrase.get("date", "🤷‍♀️")
        }, ensure_ascii=False),
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Authorization,Content-Type",
            "Access-Control-Allow-Methods": "GET,OPTIONS"
        }
    }
