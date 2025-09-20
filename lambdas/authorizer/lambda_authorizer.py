def lambda_handler(event, context):
    print("Event received:", event)

    token = event.get("authorizationToken", "")
    method_arn = event.get("methodArn")

    # Aquí defines los tokens válidos (puedes luego mover esto a DynamoDB)
    valid_tokens = ["magic-token", "devops-master-token", "kode-soul-rulez"]

    if token in valid_tokens:
        return {
            "principalId": "user|kode-soul",
            "policyDocument": {
                "Version": "2012-10-17",
                "Statement": [{
                    "Action": "execute-api:Invoke",
                    "Effect": "Allow",
                    "Resource": method_arn
                }]
            },
            "context": {
                "role": "devops"
            }
        }
    else:
        raise Exception("Unauthorized")
