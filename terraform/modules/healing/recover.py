import boto3
import json
import os
import time
import uuid

ec2 = boto3.client("ec2")
ddb = boto3.client("dynamodb")
s3 = boto3.client("s3")

BUCKET = os.environ["BUCKET"]
INSTANCE_ID = os.environ["INSTANCE_ID"]
TABLE = os.environ["TABLE"]

REBOOT_THRESHOLD = 2
WINDOW_SECONDS = 900  # 15 min


def recent_incidents():
    now = time.time()

    response = ddb.scan(TableName=TABLE)

    count = 0

    for item in response.get("Items", []):

        ts = float(item["timestamp"]["S"])
        state = item["state"]["S"]
        action = item["action"]["S"]

        if (
            now - ts < WINDOW_SECONDS
            and state == "ALARM"
            and action == "reboot"
        ):
            count += 1

    return count


def store_incident(incident_id, alarm, state, action):
    ddb.put_item(
        TableName=TABLE,
        Item={
            "incident_id": {"S": incident_id},
            "alarm": {"S": alarm},
            "state": {"S": state},
            "action": {"S": action},
            "timestamp": {"S": str(time.time())}
        }
    )


def lambda_handler(event, context):

    msg = json.loads(event["Records"][0]["Sns"]["Message"])

    if "AlarmName" not in msg:
        return {"status": "ignored"}

    alarm = msg["AlarmName"]
    state = msg["NewStateValue"]

    incident_id = str(uuid.uuid4())

    if state != "ALARM":
        store_incident(incident_id, alarm, state, "resolved")
        return {"status": "resolved"}

    incident_count = recent_incidents()

    if incident_count >= REBOOT_THRESHOLD:
        action = "escalated"

        store_incident(
            incident_id,
            alarm,
            state,
            action
        )

        print(
            f"Escalation triggered. "
            f"{incident_count} incidents in window."
        )

        return {
            "status": "escalated",
            "incident_count": incident_count
        }

    action = "pkill"

    ssm = boto3.client("ssm")

    ssm.send_command(
        InstanceIds=[INSTANCE_ID],
        DocumentName="AWS-RunShellScript",
        Parameters={
            "commands": [
                "mkdir -p /tmp/incident",
                "date > /tmp/incident/time.txt",
                "uptime > /tmp/incident/uptime.txt",
                "free -m > /tmp/incident/memory.txt",
                "df -h > /tmp/incident/disk.txt",
                "df -i > /tmp/incident/inodes.txt",
                "ss -s > /tmp/incident/network.txt",
                "ps -eo pid,cmd,%cpu,%mem --sort=-%cpu | head -20 > /tmp/incident/processes.txt",
                "journalctl -n 100 --no-pager > /tmp/incident/journal.txt",
                "pkill yes || true",
                f"tar -czf /tmp/{incident_id}.tar.gz /tmp/incident",
                f"/usr/bin/aws s3 cp /tmp/{incident_id}.tar.gz s3://{BUCKET}/",
                "echo upload-finished"
            ]
        }
    )

    print(f"SSM remediation triggered for {INSTANCE_ID}")

    store_incident(
        incident_id,
        alarm,
        state,
        action
    )

    return {
        "status": action,
        "incident_count": incident_count
    }

    