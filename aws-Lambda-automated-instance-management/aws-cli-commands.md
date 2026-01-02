# AWS CLI Commands for EC2 Setup

## Prerequisites

1. AWS CLI installed and configured
2. Valid key pair created in AWS
3. Security group created (or use default)

### Check AWS CLI Configuration
```bash
aws configure list
aws ec2 describe-regions --output table
```

### Get Latest Amazon Linux 2 AMI ID for your region
```bash
aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
  --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
  --output text
```

### List Available Key Pairs
```bash
aws ec2 describe-key-pairs --query 'KeyPairs[*].KeyName' --output table
```

### List Security Groups
```bash
aws ec2 describe-security-groups \
  --query 'SecurityGroups[*].[GroupId,GroupName]' \
  --output table
```

## Create EC2 Instances

### Method 1: Create Instance 1 (Auto-Stop) - Running State
```bash
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t2.micro \
  --key-name YOUR_KEY_NAME \
  --security-group-ids YOUR_SECURITY_GROUP \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Auto-Stop-Instance},{Key=Action,Value=Auto-Stop}]' \
  --count 1
```

### Method 2: Create Instance 2 (Auto-Start) - Running State
```bash
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t2.micro \
  --key-name YOUR_KEY_NAME \
  --security-group-ids YOUR_SECURITY_GROUP \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Auto-Start-Instance},{Key=Action,Value=Auto-Start}]' \
  --count 1
```

### Alternative: Create Without Key Pair (for testing only)
```bash
# Instance 1 (Auto-Stop)
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t2.micro \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Auto-Stop-Instance},{Key=Action,Value=Auto-Stop}]'

# Instance 2 (Auto-Start)
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t2.micro \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Auto-Start-Instance},{Key=Action,Value=Auto-Start}]'
```

## Tag Existing Instances (if already created)

### Add Tags to Existing Instances
```bash
# Tag instance as Auto-Stop
aws ec2 create-tags \
  --resources i-1234567890abcdef0 \
  --tags Key=Action,Value=Auto-Stop

# Tag instance as Auto-Start
aws ec2 create-tags \
  --resources i-0987654321fedcba0 \
  --tags Key=Action,Value=Auto-Start
```

## Stop Instance 2 for Testing
```bash
# Stop the Auto-Start instance so Lambda can start it
aws ec2 stop-instances --instance-ids i-INSTANCE2_ID
```

## Verify Setup

### List All Instances with Action Tag
```bash
aws ec2 describe-instances \
  --filters "Name=tag-key,Values=Action" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,Tags[?Key==`Action`].Value|[0],Tags[?Key==`Name`].Value|[0]]' \
  --output table
```

### Check Auto-Stop Instances
```bash
aws ec2 describe-instances \
  --filters "Name=tag:Action,Values=Auto-Stop" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' \
  --output table
```

### Check Auto-Start Instances
```bash
aws ec2 describe-instances \
  --filters "Name=tag:Action,Values=Auto-Start" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' \
  --output table
```

## Manual Testing Commands

### Manually Start an Instance
```bash
aws ec2 start-instances --instance-ids i-INSTANCE_ID
```

### Manually Stop an Instance
```bash
aws ec2 stop-instances --instance-ids i-INSTANCE_ID
```

### Wait for Instance State
```bash
# Wait for running
aws ec2 wait instance-running --instance-ids i-INSTANCE_ID

# Wait for stopped
aws ec2 wait instance-stopped --instance-ids i-INSTANCE_ID
```

## Lambda Function Setup

### Step 1: Create IAM Trust Policy
```bash
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
```

### Step 2: Create IAM Role for Lambda
```bash
aws iam create-role \
  --role-name lambda-ec2-manager-role \
  --assume-role-policy-document file:///tmp/lambda-trust-policy.json \
  --description "Role for Lambda to manage EC2 instances"
```

### Step 3: Create IAM Policy with EC2 Permissions
```bash
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

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws iam create-policy \
  --policy-name lambda-ec2-manager-policy \
  --policy-document file:///tmp/lambda-ec2-policy.json
```

### Step 4: Attach Policy to Role
```bash
aws iam attach-role-policy \
  --role-name lambda-ec2-manager-role \
  --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/lambda-ec2-manager-policy
```

### Step 5: Create Lambda Deployment Package
```bash
zip -j /tmp/lambda-function.zip lambda_ec2_manager.py
```

### Step 6: Create Lambda Function
```bash
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws lambda create-function \
  --function-name ec2-auto-manager \
  --runtime python3.12 \
  --role arn:aws:iam::${AWS_ACCOUNT_ID}:role/lambda-ec2-manager-role \
  --handler lambda_ec2_manager.lambda_handler \
  --zip-file fileb:///tmp/lambda-function.zip \
  --timeout 60 \
  --memory-size 128 \
  --description "Auto-start and auto-stop EC2 instances based on Action tags"
```

### Step 7: Test Lambda Function
```bash
aws lambda invoke \
  --function-name ec2-auto-manager \
  --payload '{}' \
  /tmp/lambda-response.json

cat /tmp/lambda-response.json
```

### Update Lambda Function Code
```bash
# If you need to update the code
zip -j /tmp/lambda-function.zip lambda_ec2_manager.py

aws lambda update-function-code \
  --function-name ec2-auto-manager \
  --zip-file fileb:///tmp/lambda-function.zip
```

### View Lambda Function Details
```bash
aws lambda get-function --function-name ec2-auto-manager
```

### List Lambda Functions
```bash
aws lambda list-functions --query 'Functions[*].[FunctionName,Runtime,Handler]' --output table
```

## CloudWatch Logs

### Tail Lambda Logs (Real-time)
```bash
aws logs tail /aws/lambda/ec2-auto-manager --follow
```

### Get Recent Log Events
```bash
# Get latest log stream
LOG_STREAM=$(aws logs describe-log-streams \
  --log-group-name /aws/lambda/ec2-auto-manager \
  --order-by LastEventTime \
  --descending \
  --max-items 1 \
  --query 'logStreams[0].logStreamName' \
  --output text)

# Get log events
aws logs get-log-events \
  --log-group-name /aws/lambda/ec2-auto-manager \
  --log-stream-name $LOG_STREAM \
  --limit 20
```

## EventBridge (Optional Scheduling)

### Create Rule to Trigger Lambda Every 5 Minutes
```bash
aws events put-rule \
  --name ec2-auto-manager-schedule \
  --schedule-expression "rate(5 minutes)" \
  --description "Trigger EC2 auto-manager Lambda every 5 minutes"

# Add permission for EventBridge to invoke Lambda
aws lambda add-permission \
  --function-name ec2-auto-manager \
  --statement-id EventBridgeInvoke \
  --action lambda:InvokeFunction \
  --principal events.amazonaws.com \
  --source-arn arn:aws:events:REGION:ACCOUNT_ID:rule/ec2-auto-manager-schedule

# Add Lambda as target
aws events put-targets \
  --rule ec2-auto-manager-schedule \
  --targets "Id"="1","Arn"="arn:aws:lambda:REGION:ACCOUNT_ID:function:ec2-auto-manager"
```

### Create Rule with Cron Expression (Daily at 9 AM UTC)
```bash
aws events put-rule \
  --name ec2-auto-manager-daily \
  --schedule-expression "cron(0 9 * * ? *)" \
  --description "Trigger EC2 auto-manager Lambda daily at 9 AM UTC"
```

### Disable/Enable Schedule
```bash
# Disable
aws events disable-rule --name ec2-auto-manager-schedule

# Enable
aws events enable-rule --name ec2-auto-manager-schedule
```

### Delete Schedule
```bash
aws events remove-targets --rule ec2-auto-manager-schedule --ids 1
aws events delete-rule --name ec2-auto-manager-schedule
```

## Cleanup Commands

### Delete Lambda Function
```bash
aws lambda delete-function --function-name ec2-auto-manager
```

### Delete CloudWatch Logs
```bash
aws logs delete-log-group --log-group-name /aws/lambda/ec2-auto-manager
```

### Delete IAM Resources
```bash
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Detach policy from role
aws iam detach-role-policy \
  --role-name lambda-ec2-manager-role \
  --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/lambda-ec2-manager-policy

# Delete policy
aws iam delete-policy \
  --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/lambda-ec2-manager-policy

# Delete role
aws iam delete-role --role-name lambda-ec2-manager-role
```

### Terminate Instances
```bash
# Terminate specific instances
aws ec2 terminate-instances --instance-ids i-INSTANCE1_ID i-INSTANCE2_ID

# Or terminate all instances with Action tag
INSTANCE_IDS=$(aws ec2 describe-instances \
  --filters "Name=tag-key,Values=Action" "Name=instance-state-name,Values=running,stopped" \
  --query 'Reservations[*].Instances[*].InstanceId' \
  --output text)

aws ec2 terminate-instances --instance-ids $INSTANCE_IDS
```

## Common AMI IDs by Region (Amazon Linux 2)

**Note:** AMI IDs change frequently. Use the describe-images command above to get the latest.

- **us-east-1**: ami-0c55b159cbfafe1f0
- **us-west-2**: ami-0873b46c45c11058d
- **eu-west-1**: ami-0d71ea30463e0ff8d
- **ap-south-1**: ami-0c1a7f89451184c8b

Run this to get your region:
```bash
aws configure get region
```
