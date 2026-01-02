import boto3
import json

def lambda_handler(event, context):
    """
    Lambda function to manage EC2 instances based on Action tags.
    - Stops instances tagged with Action=Auto-Stop
    - Starts instances tagged with Action=Auto-Start
    """
    
    # Initialize boto3 EC2 client
    ec2_client = boto3.client('ec2')
    
    try:
        # Describe instances with Auto-Stop tag
        auto_stop_response = ec2_client.describe_instances(
            Filters=[
                {
                    'Name': 'tag:Action',
                    'Values': ['Auto-Stop']
                },
                {
                    'Name': 'instance-state-name',
                    'Values': ['running']
                }
            ]
        )
        
        # Describe instances with Auto-Start tag
        auto_start_response = ec2_client.describe_instances(
            Filters=[
                {
                    'Name': 'tag:Action',
                    'Values': ['Auto-Start']
                },
                {
                    'Name': 'instance-state-name',
                    'Values': ['stopped']
                }
            ]
        )
        
        # Extract instance IDs for Auto-Stop
        stop_instance_ids = []
        for reservation in auto_stop_response['Reservations']:
            for instance in reservation['Instances']:
                stop_instance_ids.append(instance['InstanceId'])
        
        # Extract instance IDs for Auto-Start
        start_instance_ids = []
        for reservation in auto_start_response['Reservations']:
            for instance in reservation['Instances']:
                start_instance_ids.append(instance['InstanceId'])
        
        # Stop instances with Auto-Stop tag
        if stop_instance_ids:
            ec2_client.stop_instances(InstanceIds=stop_instance_ids)
            print(f"Stopped instances: {', '.join(stop_instance_ids)}")
        else:
            print("No running instances found with Auto-Stop tag")
        
        # Start instances with Auto-Start tag
        if start_instance_ids:
            ec2_client.start_instances(InstanceIds=start_instance_ids)
            print(f"Started instances: {', '.join(start_instance_ids)}")
        else:
            print("No stopped instances found with Auto-Start tag")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'EC2 instance management completed successfully',
                'stopped_instances': stop_instance_ids,
                'started_instances': start_instance_ids
            })
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Error managing EC2 instances',
                'error': str(e)
            })
        }
