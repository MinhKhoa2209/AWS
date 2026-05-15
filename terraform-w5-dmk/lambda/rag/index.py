import json
import os


def handler(event, context):
    body = {}
    raw_body = event.get("body") if isinstance(event, dict) else None
    if raw_body:
        try:
            body = json.loads(raw_body)
        except json.JSONDecodeError:
            body = {"raw": raw_body}

    return {
        "statusCode": 200,
        "headers": {"content-type": "application/json"},
        "body": json.dumps(
            {
                "ok": True,
                "stack": "xops-w5-dmk",
                "region": os.environ.get("AWS_REGION"),
                "input": body,
            }
        ),
    }
