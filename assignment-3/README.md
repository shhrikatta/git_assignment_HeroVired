# S3 Bucket Encryption Checker - AWS Lambda Function

This AWS Lambda function audits all S3 buckets in your AWS account to identify buckets that do not have server-side encryption enabled.

## Features

- ✅ Lists all S3 buckets in the AWS account
- ✅ Checks encryption configuration for each bucket
- ✅ Identifies buckets without server-side encryption
- ✅ Logs unencrypted bucket names to CloudWatch
- ✅ Returns detailed JSON response with encryption status
- ✅ Supports all S3 encryption types (SSE-S3, SSE-KMS, SSE-C)

## Prerequisites

- AWS Account
- AWS CLI configured (for deployment)
- Python 3.9 or higher
- IAM permissions to create Lambda functions and IAM roles

## IAM Permissions

The Lambda function requires the following IAM permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListAllMyBuckets",
        "s3:GetEncryptionConfiguration"
      ],
      "Resource": "*"
    }
  ]
}
```

## Deployment

### Option 1: AWS Console

1. Navigate to AWS Lambda console
2. Click "Create function"
3. Choose "Author from scratch"
4. Configure:
   - **Function name**: `s3-encryption-checker`
   - **Runtime**: Python 3.9 or higher
   - **Architecture**: x86_64
5. Click "Create function"
6. Copy the contents of `lambda_function.py` into the code editor
7. Click "Deploy"
8. Under "Configuration" → "Permissions", attach the IAM policy above to the execution role
9. Optionally configure timeout (recommended: 1 minute for many buckets)

### Option 2: AWS CLI

1. Create an IAM role for Lambda:

```bash
aws iam create-role \
  --role-name lambda-s3-encryption-checker-role \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "lambda.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'
```

2. Attach necessary policies:

```bash
# Attach basic Lambda execution policy
aws iam attach-role-policy \
  --role-name lambda-s3-encryption-checker-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Create and attach S3 read policy
aws iam put-role-policy \
  --role-name lambda-s3-encryption-checker-role \
  --policy-name S3EncryptionCheckPolicy \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": [
        "s3:ListAllMyBuckets",
        "s3:GetEncryptionConfiguration"
      ],
      "Resource": "*"
    }]
  }'
```

3. Package and deploy the function:

```bash
# Create deployment package
zip lambda_function.zip lambda_function.py

# Create Lambda function (replace ACCOUNT_ID with your AWS account ID)
aws lambda create-function \
  --function-name s3-encryption-checker \
  --runtime python3.9 \
  --role arn:aws:iam::ACCOUNT_ID:role/lambda-s3-encryption-checker-role \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://lambda_function.zip \
  --timeout 60 \
  --description "Checks S3 buckets for encryption configuration"
```

### Option 3: Using Terraform

```hcl
resource "aws_iam_role" "lambda_role" {
  name = "lambda-s3-encryption-checker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "s3-encryption-check-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets",
          "s3:GetEncryptionConfiguration"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "s3_encryption_checker" {
  filename      = "lambda_function.zip"
  function_name = "s3-encryption-checker"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  timeout       = 60

  source_code_hash = filebase64sha256("lambda_function.zip")
}
```

## Usage

### Manual Invocation (AWS Console)

1. Navigate to the Lambda function in AWS Console
2. Click "Test"
3. Create a new test event (empty JSON `{}` is sufficient)
4. Click "Test" to execute

### AWS CLI Invocation

```bash
aws lambda invoke \
  --function-name s3-encryption-checker \
  --payload '{}' \
  response.json

cat response.json
```

### Scheduled Execution (EventBridge)

Create a CloudWatch Events rule to run the function periodically:

```bash
# Create rule to run daily at midnight UTC
aws events put-rule \
  --name s3-encryption-daily-check \
  --schedule-expression "cron(0 0 * * ? *)"

# Add Lambda as target
aws events put-targets \
  --rule s3-encryption-daily-check \
  --targets "Id"="1","Arn"="arn:aws:lambda:REGION:ACCOUNT_ID:function:s3-encryption-checker"

# Grant EventBridge permission to invoke Lambda
aws lambda add-permission \
  --function-name s3-encryption-checker \
  --statement-id s3-encryption-daily-check \
  --action lambda:InvokeFunction \
  --principal events.amazonaws.com \
  --source-arn arn:aws:events:REGION:ACCOUNT_ID:rule/s3-encryption-daily-check
```

## Response Format

### Success Response (200)

```json
{
  "statusCode": 200,
  "body": {
    "message": "S3 encryption check completed successfully",
    "total_buckets": 10,
    "encrypted_count": 7,
    "unencrypted_count": 3,
    "unencrypted_buckets": [
      "my-unencrypted-bucket-1",
      "my-unencrypted-bucket-2",
      "my-unencrypted-bucket-3"
    ],
    "encrypted_buckets": [
      {
        "name": "my-encrypted-bucket-1",
        "encryption_type": "AES256"
      },
      {
        "name": "my-encrypted-bucket-2",
        "encryption_type": "aws:kms"
      }
    ]
  },
  "headers": {
    "Content-Type": "application/json"
  }
}
```

### Error Response (500)

```json
{
  "statusCode": 500,
  "body": {
    "message": "Error checking S3 bucket encryption",
    "error": "Access Denied"
  },
  "headers": {
    "Content-Type": "application/json"
  }
}
```

## CloudWatch Logs

The function logs detailed information to CloudWatch Logs:

- Bucket names being checked
- Encryption status for each bucket
- Summary of unencrypted buckets
- Any errors encountered

Example log output:

```
Starting S3 bucket encryption check...
Initializing S3 client...
Listing all S3 buckets...
Found 10 bucket(s)
Checking encryption status for each bucket...
✓ my-encrypted-bucket-1: Encrypted (AES256)
⚠️  my-unencrypted-bucket-1: Not encrypted
✓ my-encrypted-bucket-2: Encrypted (aws:kms)

============================================================
UNENCRYPTED BUCKETS DETECTED
============================================================

⚠️  Found 1 unencrypted bucket(s):

  • my-unencrypted-bucket-1

============================================================
Summary: 1/10 buckets without encryption
============================================================
```

## Monitoring and Alerting

### CloudWatch Alarm for Unencrypted Buckets

You can parse the CloudWatch Logs to create alarms:

```bash
aws cloudwatch put-metric-filter \
  --log-group-name /aws/lambda/s3-encryption-checker \
  --filter-name UnencryptedBucketsFound \
  --filter-pattern '[msg="⚠️*Not encrypted"]' \
  --metric-transformations \
    metricName=UnencryptedBuckets,\
    metricNamespace=S3Security,\
    metricValue=1

aws cloudwatch put-metric-alarm \
  --alarm-name s3-unencrypted-buckets-alert \
  --alarm-description "Alert when unencrypted S3 buckets are found" \
  --metric-name UnencryptedBuckets \
  --namespace S3Security \
  --statistic Sum \
  --period 300 \
  --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --evaluation-periods 1
```

## Troubleshooting

### Common Issues

1. **Access Denied Error**
   - Ensure the Lambda execution role has the required S3 permissions
   - Verify IAM policy is attached correctly

2. **Timeout Error**
   - Increase Lambda timeout (Configuration → General configuration → Timeout)
   - Default timeout may be too short for accounts with many buckets

3. **No Buckets Found**
   - Verify you're checking the correct AWS account
   - Ensure Lambda has `s3:ListAllMyBuckets` permission

## Security Best Practices

1. **Least Privilege**: Only grant necessary permissions
2. **Regular Audits**: Run this function periodically (daily/weekly)
3. **Enable Encryption**: Fix unencrypted buckets promptly
4. **Use KMS**: Consider using AWS KMS for enhanced security
5. **Monitor Logs**: Review CloudWatch Logs regularly

## Cost Considerations

- Lambda execution cost: Minimal (fractions of a cent per execution)
- S3 API calls: `ListBuckets` and `GetBucketEncryption` are low cost
- CloudWatch Logs: Standard logging rates apply

## Contributing

Feel free to submit issues or pull requests for improvements.

## License

MIT License
