import boto3
import json

ddb = boto3.client("dynamodb")

def lambda_handler(event, context):

    response = ddb.scan(
        TableName="cloud-ops-incidents"
    )

    incidents = []

    for item in response["Items"]:
        incidents.append({
            "incident_id": item["incident_id"]["S"],
            "alarm": item["alarm"]["S"],
            "action": item["action"]["S"],
            "state": item["state"]["S"],
            "timestamp": item["timestamp"]["S"]
        })

    return {
        "statusCode": 200,
        "headers": {
            "Access-Control-Allow-Origin": "*"
        },
        "body": json.dumps(incidents)
    }