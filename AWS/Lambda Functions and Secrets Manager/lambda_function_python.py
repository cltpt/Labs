import urllib3
import os
import json

### Load in Lambda environment variables
port = os.environ['PARAMETERS_SECRETS_EXTENSION_HTTP_PORT']
aws_session_token = os.environ['AWS_SESSION_TOKEN']
creds_path = "my_secret1"
http = urllib3.PoolManager()

### Define function to retrieve values from extension local HTTP server cachce
def retrieve_extension_value(url): 
    url = ('http://localhost:' + port + url)
    headers = { "X-Aws-Parameters-Secrets-Token": os.environ.get('AWS_SESSION_TOKEN') }
    response = http.request("GET", url, headers=headers)
    response = json.loads(response.data)   
    return response  

def lambda_handler(event, context):
    ### Load Secrets Manager values from extension
    print("Loading AWS Secrets Manager values from " + creds_path)
    secrets_url = ('/secretsmanager/get?secretId=' + creds_path)
    secret_string = json.loads(retrieve_extension_value(secrets_url)['SecretString'])

    return "Sucessfully loaded value from secrets manager.  Here it is: " + json.dumps(secret_string)