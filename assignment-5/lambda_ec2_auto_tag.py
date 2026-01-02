import boto3
from datetime import datetime

def lambda_handler(event, context):
    """
    AWS Lambda function to automatically tag newly launched EC2 instances.
    This function is triggered by CloudWatch Events when an EC2 instance is launched.
    """
    
    # Initialize boto3 EC2 client
    ec2_client = boto3.client('ec2')
    
    # Retrieve the instance ID from the event
    # The event structure from CloudWatch Events for EC2 state change
    instance_id = event['detail']['instance-id']
    
    # Get current date in YYYY-MM-DD format
    current_date = datetime.now().strftime('%Y-%m-%d')
    
    # Define tags to apply
    tags = [
        {
            'Key': 'LaunchDate',
            'Value': current_date
        },
        {
            'Key': 'AutoTagged',
            'Value': 'true'
        },
        {
            'Key': 'ManagedBy',
            'Value': 'Hero Vired'
        }
    ]
    
    # Tag the new instance
    try:
        ec2_client.create_tags(
            Resources=[instance_id],
            Tags=tags
        )
        
        # Print confirmation message for logging
        print(f"Successfully tagged EC2 instance {instance_id}")
        print(f"Tags applied: LaunchDate={current_date}, AutoTagged=true, ManagedBy=Lambda")
        
        return {
            'statusCode': 200,
            'body': f'Successfully tagged instance {instance_id}'
        }
        
    except Exception as e:
        print(f"Error tagging instance {instance_id}: {str(e)}")
        raise e
