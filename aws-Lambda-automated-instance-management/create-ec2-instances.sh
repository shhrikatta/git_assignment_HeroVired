#!/bin/bash

# AWS CLI Script to Create and Tag EC2 Instances for Lambda Assignment
# This script creates two t2.micro instances and tags them for auto-start/stop

echo "Creating EC2 instances..."

# Variables - Update these based on your AWS setup
AMI_ID="ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI (update for your region)
INSTANCE_TYPE="t2.micro"
KEY_NAME="your-key-pair"  # Replace with your key pair name
SECURITY_GROUP="your-security-group-id"  # Replace with your security group ID
SUBNET_ID="your-subnet-id"  # Optional: Replace with your subnet ID

# Create Instance 1 with Auto-Stop tag
echo "Creating Instance 1 (Auto-Stop)..."
INSTANCE1_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids $SECURITY_GROUP \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Auto-Stop-Instance},{Key=Action,Value=Auto-Stop}]" \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Instance 1 created: $INSTANCE1_ID"

# Create Instance 2 with Auto-Start tag
echo "Creating Instance 2 (Auto-Start)..."
INSTANCE2_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids $SECURITY_GROUP \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Auto-Start-Instance},{Key=Action,Value=Auto-Start}]" \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Instance 2 created: $INSTANCE2_ID"

# Wait for instances to be in running state
echo "Waiting for instances to be running..."
aws ec2 wait instance-running --instance-ids $INSTANCE1_ID $INSTANCE2_ID

# Stop Instance 2 so it's ready for Auto-Start testing
echo "Stopping Instance 2 for Auto-Start testing..."
aws ec2 stop-instances --instance-ids $INSTANCE2_ID

# Verify tags
echo -e "\nVerifying tags..."
echo "Instance 1 tags:"
aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCE1_ID"

echo -e "\nInstance 2 tags:"
aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCE2_ID"

echo -e "\n✅ EC2 instances setup complete!"
echo "Instance 1 (Auto-Stop): $INSTANCE1_ID - Running"
echo "Instance 2 (Auto-Start): $INSTANCE2_ID - Stopped"

# ============================================
# Lambda Function Setup
# ============================================

echo -e "\n========================================"
echo "Setting up Lambda Function..."
echo "========================================"

# Variables for Lambda
LAMBDA_FUNCTION_NAME="ec2-auto-manager"
LAMBDA_ROLE_NAME="lambda-ec2-manager-role"
LAMBDA_POLICY_NAME="lambda-ec2-manager-policy"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region)

# Step 1: Create IAM Trust Policy for Lambda
echo "Creating IAM trust policy..."
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
echo "Creating IAM role: $LAMBDA_ROLE_NAME..."
aws iam create-role \
  --role-name $LAMBDA_ROLE_NAME \
  --assume-role-policy-document file:///tmp/lambda-trust-policy.json \
  --description "Role for Lambda to manage EC2 instances"

# Step 3: Create IAM Policy with minimal permissions
echo "Creating IAM policy: $LAMBDA_POLICY_NAME..."
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
  --output text)

echo "Policy created: $POLICY_ARN"

# Step 4: Attach policy to role
echo "Attaching policy to role..."
aws iam attach-role-policy \
  --role-name $LAMBDA_ROLE_NAME \
  --policy-arn $POLICY_ARN

# Wait for IAM role to be available
echo "Waiting for IAM role to propagate (10 seconds)..."
sleep 10

# Step 5: Create Lambda deployment package
echo "Creating Lambda deployment package..."
zip -j /tmp/lambda-function.zip lambda_ec2_manager.py

# Step 6: Create Lambda function
echo "Creating Lambda function: $LAMBDA_FUNCTION_NAME..."
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
  --output text)

echo "Lambda function created: $LAMBDA_ARN"

# Step 7: Test the Lambda function
echo -e "\nTesting Lambda function..."
aws lambda invoke \
  --function-name $LAMBDA_FUNCTION_NAME \
  --payload '{}' \
  /tmp/lambda-response.json

echo -e "\nLambda response:"
cat /tmp/lambda-response.json
echo ""

# Step 8: View CloudWatch logs
echo -e "\nFetching CloudWatch logs..."
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
  aws logs get-log-events \
    --log-group-name $LOG_GROUP \
    --log-stream-name $LATEST_LOG_STREAM \
    --limit 20 \
    --query 'events[*].message' \
    --output text
else
  echo "CloudWatch logs not yet available. Check later with:"
  echo "aws logs tail $LOG_GROUP --follow"
fi

# Cleanup temporary files
rm -f /tmp/lambda-trust-policy.json /tmp/lambda-ec2-policy.json /tmp/lambda-function.zip /tmp/lambda-response.json

echo -e "\n========================================"
echo "✅ Complete Setup Summary"
echo "========================================"
echo "EC2 Instances:"
echo "  - Instance 1 (Auto-Stop): $INSTANCE1_ID - Running"
echo "  - Instance 2 (Auto-Start): $INSTANCE2_ID - Stopped"
echo ""
echo "IAM Resources:"
echo "  - Role: $LAMBDA_ROLE_NAME"
echo "  - Policy: $LAMBDA_POLICY_NAME"
echo "  - Policy ARN: $POLICY_ARN"
echo ""
echo "Lambda Function:"
echo "  - Function Name: $LAMBDA_FUNCTION_NAME"
echo "  - Function ARN: $LAMBDA_ARN"
echo "  - Runtime: Python 3.12"
echo ""
echo "Next Steps:"
echo "  1. Verify EC2 instances: aws ec2 describe-instances --instance-ids $INSTANCE1_ID $INSTANCE2_ID"
echo "  2. Test Lambda again: aws lambda invoke --function-name $LAMBDA_FUNCTION_NAME /tmp/out.json"
echo "  3. View logs: aws logs tail /aws/lambda/$LAMBDA_FUNCTION_NAME --follow"
echo "  4. Schedule Lambda: Use EventBridge to trigger on a schedule"
echo "========================================"
