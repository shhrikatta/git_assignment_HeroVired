import boto3
import json
from datetime import datetime, timezone, timedelta

def lambda_handler(event, context):
    """
    AWS Lambda function to delete S3 objects older than specified days.
    
    Event parameters:
        bucket_name (required): Name of the S3 bucket
        days (optional): Number of days threshold (default: 30)
    """
    # Get parameters from event
    bucket_name = event.get('bucket_name')
    days = event.get('days', 30)
    
    if not bucket_name:
        return {
            'statusCode': 400,
            'body': json.dumps({
                'error': 'bucket_name is required in event payload'
            })
        }
    
    # Initialize S3 client
    s3_client = boto3.client('s3')
    
    # Calculate the cutoff date
    cutoff_date = datetime.now(timezone.utc) - timedelta(days=days)
    
    deleted_objects = []
    error_objects = []
    
    try:
        # List objects in the bucket
        paginator = s3_client.get_paginator('list_objects_v2')
        pages = paginator.paginate(Bucket=bucket_name)
        
        for page in pages:
            if 'Contents' not in page:
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'message': 'No objects found in bucket',
                        'bucket': bucket_name,
                        'deleted_count': 0
                    })
                }
            
            for obj in page['Contents']:
                object_key = obj['Key']
                last_modified = obj['LastModified']
                
                # Check if object is older than cutoff date
                if last_modified < cutoff_date:
                    try:
                        # Delete the object
                        s3_client.delete_object(Bucket=bucket_name, Key=object_key)
                        deleted_objects.append({
                            'key': object_key,
                            'last_modified': last_modified.isoformat()
                        })
                        print(f"Deleted: {object_key}")
                    except Exception as e:
                        error_msg = f"Error deleting {object_key}: {str(e)}"
                        print(error_msg)
                        error_objects.append({
                            'key': object_key,
                            'error': str(e)
                        })
        
        # Prepare response
        response = {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Deletion completed',
                'bucket': bucket_name,
                'cutoff_date': cutoff_date.isoformat(),
                'deleted_count': len(deleted_objects),
                'deleted_objects': deleted_objects,
                'error_count': len(error_objects),
                'errors': error_objects
            })
        }
        
        print(f"Total objects deleted: {len(deleted_objects)}")
        return response
        
    except Exception as e:
        error_msg = f"Error listing objects: {str(e)}"
        print(error_msg)
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': error_msg,
                'bucket': bucket_name
            })
        }
