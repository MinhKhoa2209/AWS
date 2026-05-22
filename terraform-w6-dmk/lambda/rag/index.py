import json
import os
import boto3


bedrock = boto3.client("bedrock-runtime")


def _extract_text(body):
    for key in ("prompt", "question", "query", "message"):
        value = body.get(key)
        if isinstance(value, str) and value.strip():
            return value.strip()
    return json.dumps(body)


def _invoke_bedrock(prompt):
    model_id = os.environ.get("BEDROCK_MODEL_ID", "amazon.titan-text-express-v1")
    response = bedrock.invoke_model(
        modelId=model_id,
        contentType="application/json",
        accept="application/json",
        body=json.dumps({
            "inputText": prompt,
            "textGenerationConfig": {
                "maxTokenCount": 512,
                "temperature": 0.2,
                "topP": 0.9,
            },
        }),
    )
    payload = json.loads(response["body"].read())
    results = payload.get("results") or []
    if results and "outputText" in results[0]:
        return results[0]["outputText"]
    return payload


def handler(event, context):
    body = {}
    raw_body = event.get("body") if isinstance(event, dict) else None
    if raw_body:
        try:
            body = json.loads(raw_body)
        except json.JSONDecodeError:
            body = {"raw": raw_body}

    prompt = _extract_text(body)

    try:
        answer = _invoke_bedrock(prompt)
        status_code = 200
        response_body = {
            "ok": True,
            "stack": "xops-w6-dmk",
            "region": os.environ.get("AWS_REGION"),
            "model": os.environ.get("BEDROCK_MODEL_ID"),
            "answer": answer,
        }
    except Exception as exc:
        status_code = 502
        response_body = {
            "ok": False,
            "error": str(exc),
            "input": body,
        }

    return {
        "statusCode": status_code,
        "headers": {"content-type": "application/json"},
        "body": json.dumps(response_body),
    }
