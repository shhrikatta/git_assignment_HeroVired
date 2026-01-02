# EC2 Auto-Tagging Lambda Function

## Overview

This project contains an AWS Lambda function that automatically tags newly launched EC2 instances with the current date and custom tags. This ensures better resource tracking and management across your AWS environment.

## Features

- Automatically tags EC2 instances when they are launched
- Applies three tags:
  - **LaunchDate**: Current date (YYYY-MM-DD format)
  - **AutoTagged**: Set to "true"
  - **ManagedBy**: Set to "Lambda"
- Logs confirmation messages for monitoring

## Prerequisites

- AWS Account
- AWS CLI configured
- Python 3.x
- Boto3 library
- Appropriate IAM permissions

## Files

- `lambda_ec2_auto_tag.py` - Main Lambda function code

## Deployment Steps

### 1. Create IAM Role for Lambda

Create an IAM role with the following permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateTags",
        "ec2:DescribeInstances"
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
```

### 2. Create Lambda Function

1. Go to AWS Lambda Console
2. Click "Create function"
3. Choose "Author from scratch"
4. Configure:
   - **Function name**: `EC2-Auto-Tagger`
   - **Runtime**: Python 3.9 (or later)
   - **Execution role**: Use the IAM role created in step 1
5. Copy the contents of `lambda_ec2_auto_tag.py` into the function code
6. Click "Deploy"

### 3. Create CloudWatch Events Rule

1. Go to Amazon EventBridge Console
2. Click "Create rule"
3. Configure:
   - **Name**: `EC2-Launch-Trigger`
   - **Event pattern**:
   ```json
   {
     "source": ["aws.ec2"],
     "detail-type": ["EC2 Instance State-change Notification"],
     "detail": {
       "state": ["running"]
     }
   }
   ```
4. Add target:
   - **Target**: Lambda function
   - **Function**: Select `EC2-Auto-Tagger`
5. Click "Create"

### 4. Test the Function

1. Launch a new EC2 instance
2. Check CloudWatch Logs for the Lambda function
3. Verify the tags on the newly launched instance:
   ```bash
   aws ec2 describe-tags --filters "Name=resource-id,Values=<instance-id>"
   ```

## How It Works

1. When an EC2 instance transitions to the "running" state, CloudWatch Events triggers the Lambda function
2. The function receives the event with the instance ID
3. It creates and applies tags to the instance using boto3
4. Logs a confirmation message to CloudWatch Logs

## Event Structure

The Lambda function expects a CloudWatch Event with the following structure:

```json
{
  "version": "0",
  "id": "event-id",
  "detail-type": "EC2 Instance State-change Notification",
  "source": "aws.ec2",
  "account": "123456789012",
  "time": "2026-01-02T18:00:00Z",
  "region": "us-east-1",
  "detail": {
    "instance-id": "i-1234567890abcdef0",
    "state": "running"
  }
}
```

## Monitoring

View Lambda execution logs in CloudWatch Logs:
- Log Group: `/aws/lambda/EC2-Auto-Tagger`

Expected log output:
```
Successfully tagged EC2 instance i-1234567890abcdef0
Tags applied: LaunchDate=2026-01-02, AutoTagged=true, ManagedBy=Lambda
```

## Customization

To add or modify tags, edit the `tags` list in `lambda_ec2_auto_tag.py`:

```python
tags = [
    {
        'Key': 'YourCustomKey',
        'Value': 'YourCustomValue'
    }
]
```

## Troubleshooting

### Tags not appearing on instances
- Verify the IAM role has `ec2:CreateTags` permission
- Check CloudWatch Logs for error messages
- Ensure the EventBridge rule is enabled and properly configured

### Lambda function not triggered
- Verify the EventBridge rule event pattern matches EC2 state changes
- Check that the Lambda function is added as a target
- Ensure the Lambda function has resource-based permissions to be invoked by EventBridge

## Cost Considerations

- Lambda invocations: Free tier includes 1M requests/month
- CloudWatch Events: First rule is free, additional rules may incur charges
- CloudWatch Logs: Storage and ingestion costs apply

## Security Best Practices

1. Use least privilege IAM permissions
2. Enable CloudTrail to audit tagging operations
3. Consider encrypting CloudWatch Logs
4. Regularly review and update IAM policies

## License

This project is for educational purposes as part of the HeroVired cloud assignment.
