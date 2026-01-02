#!/bin/bash

# AWS CLI Script to Setup Lambda Function for EC2 Management
# This script creates IAM role, policy, and Lambda function

echo "========================================"
echo "Lambda Function Setup"
echo "========================================"

# Variables
LAMBDA_FUNCTION_NAME="ec2-auto-manager"
LAMBDA_ROLE_NAME="lambda-ec2-manager-role"
LAMBDA_POLICY_NAME="lambda-ec2-manager-policy"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region)

echo "AWS Account ID: $AWS_ACCOUNT_ID"
echo "AWS Region: $AWS_REGION"

# Step 1: Create IAM Trust Policy for Lambda
echo -e "\n[1/8] Creating IAM trust policy..."
cat > /tmp/lambda-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Step 2: Create IAM Role for Lambda
echo "[2/8] Creating IAM role: $LAMBDA_ROLE_NAME..."
aws iam create-role \
  --role-name $LAMBDA_ROLE_NAME \
  --assume-role-policy-document file:///tmp/lambda-trust-policy.json \
  --description "Role for Lambda to manage EC2 instances" \
  2>/dev/null

if [ $? -eq 0 ]; then
  echo "✓ IAM role created successfully"
else
  echo "⚠ IAM role may already exist, continuing..."
fi

# Step 3: Create IAM Policy with minimal permissions
echo "[3/8] Creating IAM policy: $LAMBDA_POLICY_NAME..."
cat > /tmp/lambda-ec2-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:StopInstances",
        "ec2:StartInstances",
        "ec2:DescribeTags"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF

POLICY_ARN=$(aws iam create-policy \
  --policy-name $LAMBDA_POLICY_NAME \
  --policy-document file:///tmp/lambda-ec2-policy.json \
  --query 'Policy.Arn' \
  --output text 2>/dev/null)

if [ $? -eq 0 ]; then
  echo "✓ Policy created: $POLICY_ARN"
else
  echo "⚠ Policy may already exist, getting ARN..."
  POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${LAMBDA_POLICY_NAME}"
  echo "Policy ARN: $POLICY_ARN"
fi

# Step 4: Attach policy to role
echo "[4/8] Attaching policy to role..."
aws iam attach-role-policy \
  --role-name $LAMBDA_ROLE_NAME \
  --policy-arn $POLICY_ARN 2>/dev/null
echo "✓ Policy attached"

# Wait for IAM role to be available
echo "[5/8] Waiting for IAM role to propagate (10 seconds)..."
sleep 10

# Step 5: Create Lambda deployment package
echo "[6/8] Creating Lambda deployment package..."
if [ ! -f "lambda_ec2_manager.py" ]; then
  echo "❌ Error: lambda_ec2_manager.py not found in current directory"
  echo "Please ensure the Lambda function code exists"
  exit 1
fi

zip -q -j /tmp/lambda-function.zip lambda_ec2_manager.py
echo "✓ Deployment package created"

# Step 6: Create Lambda function
echo "[7/8] Creating Lambda function: $LAMBDA_FUNCTION_NAME..."
LAMBDA_ARN=$(aws lambda create-function \
  --function-name $LAMBDA_FUNCTION_NAME \
  --runtime python3.12 \
  --role arn:aws:iam::${AWS_ACCOUNT_ID}:role/${LAMBDA_ROLE_NAME} \
  --handler lambda_ec2_manager.lambda_handler \
  --zip-file fileb:///tmp/lambda-function.zip \
  --timeout 60 \
  --memory-size 128 \
  --description "Auto-start and auto-stop EC2 instances based on Action tags" \
  --query 'FunctionArn' \
  --output text 2>/dev/null)

if [ $? -eq 0 ]; then
  echo "✓ Lambda function created: $LAMBDA_ARN"
else
  echo "⚠ Lambda function may already exist, updating code..."
  aws lambda update-function-code \
    --function-name $LAMBDA_FUNCTION_NAME \
    --zip-file fileb:///tmp/lambda-function.zip \
    --query 'FunctionArn' \
    --output text
  LAMBDA_ARN="arn:aws:lambda:${AWS_REGION}:${AWS_ACCOUNT_ID}:function:${LAMBDA_FUNCTION_NAME}"
  echo "✓ Lambda function updated: $LAMBDA_ARN"
fi

# Step 7: Test the Lambda function
echo "[8/8] Testing Lambda function..."
aws lambda invoke \
  --function-name $LAMBDA_FUNCTION_NAME \
  --payload '{}' \
  --cli-binary-format raw-in-base64-out \
  /tmp/lambda-response.json > /dev/null 2>&1

echo -e "\n📄 Lambda Response:"
cat /tmp/lambda-response.json | python3 -m json.tool 2>/dev/null || cat /tmp/lambda-response.json
echo ""

# Step 8: View CloudWatch logs
echo -e "\n📋 Fetching CloudWatch Logs..."
LOG_GROUP="/aws/lambda/$LAMBDA_FUNCTION_NAME"
sleep 5  # Wait for logs to be available

LATEST_LOG_STREAM=$(aws logs describe-log-streams \
  --log-group-name $LOG_GROUP \
  --order-by LastEventTime \
  --descending \
  --max-items 1 \
  --query 'logStreams[0].logStreamName' \
  --output text 2>/dev/null)

if [ "$LATEST_LOG_STREAM" != "None" ] && [ -n "$LATEST_LOG_STREAM" ]; then
  echo "Log stream: $LATEST_LOG_STREAM"
  echo "---"
  aws logs get-log-events \
    --log-group-name $LOG_GROUP \
    --log-stream-name $LATEST_LOG_STREAM \
    --limit 20 \
    --query 'events[*].message' \
    --output text
else
  echo "⚠ CloudWatch logs not yet available. Check later with:"
  echo "aws logs tail $LOG_GROUP --follow"
fi

# Cleanup temporary files
rm -f /tmp/lambda-trust-policy.json /tmp/lambda-ec2-policy.json /tmp/lambda-function.zip /tmp/lambda-response.json

echo -e "\n========================================"
echo "✅ Lambda Setup Complete!"
echo "========================================"
echo "IAM Resources:"
echo "  - Role: $LAMBDA_ROLE_NAME"
echo "  - Policy: $LAMBDA_POLICY_NAME"
echo "  - Policy ARN: $POLICY_ARN"
echo ""
echo "Lambda Function:"
echo "  - Name: $LAMBDA_FUNCTION_NAME"
echo "  - ARN: $LAMBDA_ARN"
echo "  - Runtime: Python 3.12"
echo "  - Handler: lambda_ec2_manager.lambda_handler"
echo ""
echo "Next Steps:"
echo "  1. Test Lambda: aws lambda invoke --function-name $LAMBDA_FUNCTION_NAME /tmp/out.json && cat /tmp/out.json"
echo "  2. View logs: aws logs tail /aws/lambda/$LAMBDA_FUNCTION_NAME --follow"
echo "  3. Check EC2 instances: aws ec2 describe-instances --filters \"Name=tag-key,Values=Action\" --query 'Reservations[*].Instances[*].[InstanceId,State.Name,Tags[?Key==\`Action\`].Value|[0]]' --output table"
echo "  4. Schedule with EventBridge (optional)"
echo "========================================"
