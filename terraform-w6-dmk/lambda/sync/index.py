import json
import os
import urllib.parse
import boto3


bedrock = boto3.client("bedrock-runtime")
lambda_client = boto3.client("lambda")
s3 = boto3.client("s3")


def _summarize_object(bucket, key):
    head = s3.head_object(Bucket=bucket, Key=key)
    prompt = (
        "Summarize this newly uploaded S3 object for sync indexing. "
        f"Bucket: {bucket}. Key: {key}. Size: {head.get('ContentLength', 0)} bytes."
    )
    response = bedrock.invoke_model(
        modelId=os.environ.get("BEDROCK_MODEL_ID", "amazon.titan-text-express-v1"),
        contentType="application/json",
        accept="application/json",
        body=json.dumps({
            "inputText": prompt,
            "textGenerationConfig": {
                "maxTokenCount": 256,
                "temperature": 0.1,
                "topP": 0.9,
            },
        }),
    )
    payload = json.loads(response["body"].read())
    results = payload.get("results") or []
    if results and "outputText" in results[0]:
        return results[0]["outputText"]
    return json.dumps(payload)


def handler(event, context):
    synced = []
    for record in event.get("Records", []):
        bucket = record["s3"]["bucket"]["name"]
        key = urllib.parse.unquote_plus(record["s3"]["object"]["key"])
        summary = _summarize_object(bucket, key)
        synced.append({"bucket": bucket, "key": key, "summary": summary})

    rag_function = os.environ.get("RAG_FUNCTION_NAME")
    if rag_function and synced:
        lambda_client.invoke(
            FunctionName=rag_function,
            InvocationType="Event",
            Payload=json.dumps({"source": "sync-lambda", "items": synced}).encode("utf-8"),
        )

    return {
        "statusCode": 200,
        "body": json.dumps({"ok": True, "synced": synced}),
    }
