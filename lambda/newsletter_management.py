from flask import Flask, jsonify, request
import boto3

app = Flask(__name__)

# Create an Amazon DynamoDB resource.
dynamodb = boto3.resource('dynamodb')

# Set the name of the DynamoDB table to use.
table_name = 'food-explorer-subscribers'

# Get the DynamoDB table to use.
table = dynamodb.Table(table_name)

# Define a function to add a new subscriber to the DynamoDB table.
def add_subscriber(email):
    table.put_item(Item={
        'email': email
    })

# Define a function to remove a subscriber from the DynamoDB table.
def remove_subscriber(email):
    table.delete_item(Key={
        'email': email
    })

# Define a function to check if a subscriber exists in the DynamoDB table.
def subscriber_exists(email):
    response = table.get_item(Key={
        'email': email
    })
    return 'Item' in response

# Define an endpoint for adding a new subscriber.
@app.route('/subscribe', methods=['POST'])
def subscribe(event, context):
    email = event['email']

    # Add the subscriber to the SNS topic.
    sns.subscribe(
        TopicArn='<YOUR_SNS_TOPIC_ARN>',
        Protocol='email',
        Endpoint=email
    )

    # Create a file in the S3 bucket with the subscriber's email address as the filename.
    bucket = s3.Bucket('<YOUR_S3_BUCKET_NAME>')
    object_key = f"{email}.txt"
    bucket.put_object(
        Key=object_key,
        Body=json.dumps({
            'email': email
        })
    )

    return {
        'statusCode': 200,
        'body': 'Subscriber added successfully!'
    }

# Define an endpoint for removing a subscriber.
@app.route('/unsubscribe', methods=['DELETE'])
def unsubscribe():
    data = request.get_json()
    email = data['email']

    if not subscriber_exists(email):
        return jsonify({
            'error': 'Subscriber does not exist!'
        }), 400

    remove_subscriber(email)
    return jsonify({
        'message': 'Subscriber removed successfully!'
    }), 200

# Define a default endpoint for handling invalid requests.
@app.route('/', methods=['GET', 'POST', 'PUT', 'DELETE'])
def default():
    return jsonify({
        'error': 'Invalid request!'
    }), 400

if __name__ == '__main__':
    app.run()
