# AWS Lambda EC2 Auto-Start/Stop Assignment

This project contains a Lambda function that automatically manages EC2 instances based on tags.

## Architecture

- **Lambda Function**: Manages EC2 instances based on `Action` tags
- **EC2 Instances**: Two t2.micro instances with different tags
- **IAM Role**: Provides Lambda with permissions to manage EC2 instances

## Setup Instructions

### 1. EC2 Instance Setup

1. Navigate to EC2 Console → Instances
2. Launch two t2.micro instances (free tier eligible)
3. Tag the instances:
   - **Instance 1**: Key = `Action`, Value = `Auto-Stop`
   - **Instance 2**: Key = `Action`, Value = `Auto-Start`

### 2. IAM Role Creation

1. Navigate to IAM Console → Roles
2. Click "Create role"
3. Select "AWS service" → "Lambda"
4. Attach policy: `AmazonEC2FullAccess`
5. Name the role: `lambda-ec2-manager-role`
6. Create the role

### 3. Lambda Function Deployment

#### Using AWS Console:

1. Navigate to Lambda Console → Functions
2. Click "Create function"
3. Choose "Author from scratch"
4. Configuration:
   - Function name: `ec2-auto-manager`
   - Runtime: Python 3.12 (or latest Python 3.x)
   - Architecture: x86_64
   - Execution role: Use existing role → `lambda-ec2-manager-role`
5. Click "Create function"
6. Copy the code from `lambda_ec2_manager.py` into the function code editor
7. Click "Deploy"

#### Using AWS CLI:

```bash
# Create deployment package
zip function.zip lambda_ec2_manager.py

# Create Lambda function
aws lambda create-function \
  --function-name ec2-auto-manager \
  --runtime python3.12 \
  --role arn:aws:iam::YOUR_ACCOUNT_ID:role/lambda-ec2-manager-role \
  --handler lambda_ec2_manager.lambda_handler \
  --zip-file fileb://function.zip \
  --timeout 60
```

### 4. Testing the Lambda Function

1. In the Lambda console, click "Test"
2. Create a new test event (use the default template)
3. Click "Test" to execute the function
4. Check CloudWatch Logs for execution details

## How It Works

The Lambda function:

1. Initializes a boto3 EC2 client
2. Queries for instances with the `Auto-Stop` tag that are running
3. Queries for instances with the `Auto-Start` tag that are stopped
4. Stops all running instances tagged with `Auto-Stop`
5. Starts all stopped instances tagged with `Auto-Start`
6. Logs the instance IDs that were affected

## Function Behavior

- **Auto-Stop instances**: Only running instances will be stopped
- **Auto-Start instances**: Only stopped instances will be started
- If no instances match the criteria, appropriate messages are logged
- Returns a JSON response with the list of affected instances

## CloudWatch Logs

The function prints log messages that can be viewed in CloudWatch:
- Instance IDs that were stopped
- Instance IDs that were started
- Any errors encountered

## Optional: Schedule the Function

To run this function automatically on a schedule:

1. Navigate to EventBridge (CloudWatch Events)
2. Create a new rule
3. Set schedule expression (e.g., `rate(5 minutes)` or `cron(0 9 * * ? *)`)
4. Add target: Lambda function → `ec2-auto-manager`

## Cleanup

To avoid charges:
1. Delete the Lambda function
2. Terminate the EC2 instances
3. Delete the IAM role
4. Delete any CloudWatch Log groups

## Security Note

The `AmazonEC2FullAccess` policy provides broad permissions. For production use, create a custom policy with minimum required permissions:
- `ec2:DescribeInstances`
- `ec2:StopInstances`
- `ec2:StartInstances`
