#!/bin/bash

# AWS CLI Script to Cleanup All Resources
# This script deletes Lambda function, IAM resources, and EC2 instances

echo "========================================"
echo "AWS Resources Cleanup"
echo "========================================"
echo "⚠️  WARNING: This will delete all resources created for this assignment!"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "Cleanup cancelled."
  exit 0
fi

# Variables
LAMBDA_FUNCTION_NAME="ec2-auto-manager"
LAMBDA_ROLE_NAME="lambda-ec2-manager-role"
LAMBDA_POLICY_NAME="lambda-ec2-manager-policy"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo -e "\nStarting cleanup process...\n"

# Step 1: Delete Lambda Function
echo "[1/6] Deleting Lambda function: $LAMBDA_FUNCTION_NAME..."
aws lambda delete-function --function-name $LAMBDA_FUNCTION_NAME 2>/dev/null
if [ $? -eq 0 ]; then
  echo "✓ Lambda function deleted"
else
  echo "⚠ Lambda function not found or already deleted"
fi

# Step 2: Delete CloudWatch Log Group
echo "[2/6] Deleting CloudWatch log group..."
aws logs delete-log-group --log-group-name "/aws/lambda/$LAMBDA_FUNCTION_NAME" 2>/dev/null
if [ $? -eq 0 ]; then
  echo "✓ Log group deleted"
else
  echo "⚠ Log group not found or already deleted"
fi

# Step 3: Detach IAM Policy from Role
echo "[3/6] Detaching IAM policy from role..."
POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${LAMBDA_POLICY_NAME}"
aws iam detach-role-policy \
  --role-name $LAMBDA_ROLE_NAME \
  --policy-arn $POLICY_ARN 2>/dev/null
if [ $? -eq 0 ]; then
  echo "✓ Policy detached"
else
  echo "⚠ Policy not attached or already detached"
fi

# Step 4: Delete IAM Policy
echo "[4/6] Deleting IAM policy: $LAMBDA_POLICY_NAME..."
aws iam delete-policy --policy-arn $POLICY_ARN 2>/dev/null
if [ $? -eq 0 ]; then
  echo "✓ Policy deleted"
else
  echo "⚠ Policy not found or already deleted"
fi

# Step 5: Delete IAM Role
echo "[5/6] Deleting IAM role: $LAMBDA_ROLE_NAME..."
aws iam delete-role --role-name $LAMBDA_ROLE_NAME 2>/dev/null
if [ $? -eq 0 ]; then
  echo "✓ Role deleted"
else
  echo "⚠ Role not found or already deleted"
fi

# Step 6: Terminate EC2 Instances
echo "[6/6] Terminating EC2 instances with Action tag..."
INSTANCE_IDS=$(aws ec2 describe-instances \
  --filters "Name=tag-key,Values=Action" "Name=instance-state-name,Values=running,stopped,stopping" \
  --query 'Reservations[*].Instances[*].InstanceId' \
  --output text)

if [ -n "$INSTANCE_IDS" ]; then
  echo "Found instances: $INSTANCE_IDS"
  aws ec2 terminate-instances --instance-ids $INSTANCE_IDS
  echo "✓ EC2 instances terminated"
  echo "⏳ Instances are terminating... (this may take a few minutes)"
else
  echo "⚠ No EC2 instances found with Action tag"
fi

echo -e "\n========================================"
echo "✅ Cleanup Complete!"
echo "========================================"
echo "Deleted Resources:"
echo "  - Lambda Function: $LAMBDA_FUNCTION_NAME"
echo "  - IAM Role: $LAMBDA_ROLE_NAME"
echo "  - IAM Policy: $LAMBDA_POLICY_NAME"
echo "  - CloudWatch Log Group: /aws/lambda/$LAMBDA_FUNCTION_NAME"
if [ -n "$INSTANCE_IDS" ]; then
  echo "  - EC2 Instances: $INSTANCE_IDS (terminating)"
fi
echo ""
echo "Verify cleanup:"
echo "  aws lambda list-functions --query 'Functions[?FunctionName==\`$LAMBDA_FUNCTION_NAME\`]'"
echo "  aws ec2 describe-instances --filters \"Name=tag-key,Values=Action\" --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' --output table"
echo "========================================"
