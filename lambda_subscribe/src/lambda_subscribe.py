import boto3
import json

dynamodb = boto3.resource("dynamodb")

def lambda_handler(event, context):
    if "httpMethod" not in event:
        return {
            "statusCode": 400,
            "body": json.dumps("Bad request: HTTP method not specified.")
        }

    if event["httpMethod"] == "GET":
        return get_subscribers(event)
    elif event["httpMethod"] == "POST":
        return add_subscriber(event)
    elif event["httpMethod"] == "PUT":
        return modify_subscriber(event)
    elif event["httpMethod"] == "DELETE":
        return delete_subscriber(event)
    else:
        return {
            "statusCode": 400,
            "body": json.dumps("Bad request: unsupported HTTP method.")
        }

def get_subscribers(event):
    table_name = event["subscribers_table_name"]
    table = dynamodb.Table(table_name)

    response = table.scan()
    subscribers = response.get("Items", [])

    return {
        "statusCode": 200,
        "body": json.dumps(subscribers)
    }

def add_subscriber(event):
    table_name = event["subscribers_table_name"]
    table = dynamodb.Table(table_name)

    try:
        body = json.loads(event["body"])
    except:
        return {
            "statusCode": 400,
            "body": json.dumps("Bad request: request body is not a valid JSON object.")
        }

    if "email" not in body:
        return {
            "statusCode": 400,
            "body": json.dumps("Bad request: 'email' field is missing from request body.")
        }

    email = body["email"]
    name = body["name"] if "name" in body else None

    # Check if email is already subscribed
    response = table.get_item(Key={"email": email})
    if "Item" in response:
        return {
            "statusCode": 409,
            "body": json.dumps(f"Email address {email} is already subscribed.")
        }

    # Add email to subscribers list
    item = {"email": email}
    if name is not None:
        item["name"] = name
    table.put_item(Item=item)

    return {
        "statusCode": 200,
        "body": json.dumps(f"Email address {email} added to subscribers list.")
    }

def modify_subscriber(event):
    table_name = event["subscribers_table_name"]
    table = dynamodb.Table(table_name)

    try:
        body = json.loads(event["body"])
    except:
        return {
            "statusCode": 400,
            "body": json.dumps("Bad request: request body is not a valid JSON object.")
        }

    if "email" not in body:
        return {
            "statusCode": 400,
            "body": json.dumps("Bad request: 'email' field is missing from request body.")
        }

    email = body["email"]
    name = body["name"] if "name" in body else None

    # Check if email is already subscribed
    response = table.get_item(Key={"email": email})
    if "Item" not in response:
        return {
            "statusCode": 404,
            "body": json.dumps(f"Email address {email} is not subscribed.")
        }

    # Update subscriber name
    item = {"email": email}
    if name is not None:
        item["name"] = name
    table.put_item(Item=item)

    return {
        "statusCode": 200,
        "body": json.dumps(f"Email address {email} updated in subscribers list.")
    }

def delete_subscriber(event):
    table_name = event["subscribers_table_name"]
    table = dynamodb.Table(table_name)

    try:
        body = json.loads(event["body"])
    except:
        return {
            "statusCode": 400,
            "body": json.dumps("Bad request: request body is not a valid JSON object.")
        }

    if "email" not in body:
        return {
            "statusCode": 400,
            "body": json.dumps("Bad request: 'email' field is missing from request body.")
        }

    email = body["email"]

    # Check if email is already subscribed
    response = table.get_item(Key={"email": email})
    if "Item" not in response:
        return {
            "statusCode": 404,
            "body": json.dumps(f"Email address {email} is not subscribed.")
        }

    # Remove email from subscribers list
    table.delete_item(Key={"email": email})

    return {
        "statusCode": 200,
        "body": json.dumps(f"Email address {email} removed from subscribers list.")
    }
