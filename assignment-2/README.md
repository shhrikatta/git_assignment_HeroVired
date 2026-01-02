# S3 Object Cleanup Lambda Function

This AWS Lambda function automatically deletes objects from an S3 bucket that are older than a specified number of days (default: 30 days).

## Features

- Deletes S3 objects older than a configurable threshold
- Handles large buckets with pagination
- Comprehensive error handling and logging
- Returns detailed execution report
- CloudWatch Logs integration

## Prerequisites

- AWS Account
- Python 3.9 or higher
- AWS CLI configured (for deployment)
- Appropriate IAM permissions

## Lambda Function Setup

### 1. Create IAM Role

Create an IAM role for the Lambda function with the following policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": "arn:aws:s3:::your-bucket-name"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::your-bucket-name/*"
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
```

### 2. Deploy Lambda Function

#### Option A: AWS Console

1. Go to AWS Lambda Console
2. Click "Create function"
3. Choose "Author from scratch"
4. Configure:
   - **Function name**: `s3-object-cleanup`
   - **Runtime**: Python 3.9 or higher
   - **Execution role**: Use the IAM role created above
5. Copy the Lambda function code into the code editor
6. Configure:
   - **Timeout**: 5-15 minutes (depending on bucket size)
   - **Memory**: 256-512 MB

#### Option B: AWS CLI

```bash
# Create deployment package
zip lambda_function.zip lambda_function.py

# Create Lambda function
aws lambda create-function \
  --function-name s3-object-cleanup \
  --runtime python3.9 \
  --role arn:aws:iam::YOUR_ACCOUNT_ID:role/YOUR_LAMBDA_ROLE \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://lambda_function.zip \
  --timeout 300 \
  --memory-size 512
```

## Usage

### Event Payload

The Lambda function accepts the following parameters in the event payload:

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `bucket_name` | string | Yes | - | Name of the S3 bucket to clean up |
| `days` | integer | No | 30 | Delete objects older than this many days |

### Example Invocations

#### Delete objects older than 30 days (default)

```json
{
  "bucket_name": "my-bucket"
}
```

#### Delete objects older than 60 days

```json
{
  "bucket_name": "my-bucket",
  "days": 60
}
```

### Testing via AWS CLI

```bash
aws lambda invoke \
  --function-name s3-object-cleanup \
  --payload '{"bucket_name":"my-bucket","days":30}' \
  response.json

cat response.json
```

### Testing via AWS Console

1. Go to Lambda Console
2. Select your function
3. Click "Test" tab
4. Create a new test event with the JSON payload
5. Click "Test" to execute

## Response Format

### Success Response

```json
{
  "statusCode": 200,
  "body": {
    "message": "Deletion completed",
    "bucket": "my-bucket",
    "cutoff_date": "2025-12-03T18:00:00+00:00",
    "deleted_count": 5,
    "deleted_objects": [
      {
        "key": "old-file-1.txt",
        "last_modified": "2025-11-15T10:30:00+00:00"
      },
      {
        "key": "old-file-2.txt",
        "last_modified": "2025-11-20T14:20:00+00:00"
      }
    ],
    "error_count": 0,
    "errors": []
  }
}
```

### Error Response

```json
{
  "statusCode": 400,
  "body": {
    "error": "bucket_name is required in event payload"
  }
}
```

## Automation with EventBridge

Schedule the Lambda function to run automatically:

### 1. Create EventBridge Rule

```bash
aws events put-rule \
  --name s3-cleanup-daily \
  --schedule-expression "cron(0 2 * * ? *)"
```

### 2. Add Lambda Target

```bash
aws events put-targets \
  --rule s3-cleanup-daily \
  --targets "Id"="1","Arn"="arn:aws:lambda:REGION:ACCOUNT_ID:function:s3-object-cleanup","Input"='{"bucket_name":"my-bucket","days":30}'
```

### 3. Grant EventBridge Permission

```bash
aws lambda add-permission \
  --function-name s3-object-cleanup \
  --statement-id eventbridge-invoke \
  --action lambda:InvokeFunction \
  --principal events.amazonaws.com \
  --source-arn arn:aws:events:REGION:ACCOUNT_ID:rule/s3-cleanup-daily
```

### Common Schedule Expressions

- Daily at 2 AM UTC: `cron(0 2 * * ? *)`
- Weekly on Sundays at 3 AM UTC: `cron(0 3 ? * SUN *)`
- Every 12 hours: `rate(12 hours)`
- Every 7 days: `rate(7 days)`

## Monitoring

### CloudWatch Logs

View execution logs:

```bash
aws logs tail /aws/lambda/s3-object-cleanup --follow
```

### CloudWatch Metrics

Monitor Lambda function metrics:
- Invocations
- Duration
- Errors
- Throttles

## Best Practices

1. **Test on non-production buckets first**
2. **Enable S3 versioning** as a safety net before running deletions
3. **Set appropriate timeout** based on bucket size
4. **Monitor CloudWatch Logs** for errors
5. **Use S3 Lifecycle policies** for routine cleanups instead of Lambda for cost optimization
6. **Implement DLQ (Dead Letter Queue)** for failed invocations

## Troubleshooting

### Permission Denied Errors

Ensure the Lambda execution role has:
- `s3:ListBucket` on bucket
- `s3:DeleteObject` on bucket objects

### Timeout Errors

- Increase Lambda timeout (max 15 minutes)
- Consider processing in batches for very large buckets

### No Objects Deleted

- Check the `days` parameter is correct
- Verify object timestamps in S3
- Review CloudWatch Logs for details

## Cost Considerations

- **Lambda**: Charged per request and execution time
- **S3**: No charge for DELETE operations
- **CloudWatch Logs**: Storage and data ingestion charges

For large-scale routine cleanups, consider using **S3 Lifecycle policies** as a more cost-effective alternative.

## License

This project is provided as-is for educational and demonstration purposes.
