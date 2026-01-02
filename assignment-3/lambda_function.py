"""
AWS Lambda Function: S3 Bucket Encryption Checker

This Lambda function checks all S3 buckets in an AWS account and identifies
buckets that do not have server-side encryption enabled.
"""

import boto3
import json
from botocore.exceptions import ClientError


def initialize_s3_client():
    """Initialize and return a boto3 S3 client."""
    return boto3.client('s3')


def list_all_buckets(s3_client):
    """
    List all S3 buckets in the account.
    
    Args:
        s3_client: Boto3 S3 client instance
        
    Returns:
        List of bucket names
    """
    try:
        response = s3_client.list_buckets()
        return [bucket['Name'] for bucket in response.get('Buckets', [])]
    except ClientError as e:
        print(f"Error listing buckets: {e}")
        raise


def check_bucket_encryption(s3_client, bucket_name):
    """
    Check if a bucket has server-side encryption enabled.
    
    Args:
        s3_client: Boto3 S3 client instance
        bucket_name: Name of the bucket to check
        
    Returns:
        dict with encryption status and details
    """
    try:
        response = s3_client.get_bucket_encryption(Bucket=bucket_name)
        rules = response.get('ServerSideEncryptionConfiguration', {}).get('Rules', [])
        return {
            'encrypted': True,
            'encryption_type': rules[0].get('ApplyServerSideEncryptionByDefault', {}).get('SSEAlgorithm', 'Unknown') if rules else 'Unknown'
        }
    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == 'ServerSideEncryptionConfigurationNotFoundError':
            return {'encrypted': False, 'encryption_type': None}
        else:
            print(f"Error checking encryption for bucket {bucket_name}: {e}")
            return {'encrypted': False, 'encryption_type': None, 'error': str(e)}


def detect_unencrypted_buckets(s3_client, buckets):
    """
    Detect buckets without server-side encryption.
    
    Args:
        s3_client: Boto3 S3 client instance
        buckets: List of bucket names to check
        
    Returns:
        dict with unencrypted and encrypted bucket information
    """
    unencrypted_buckets = []
    encrypted_buckets = []
    
    for bucket in buckets:
        encryption_status = check_bucket_encryption(s3_client, bucket)
        
        if encryption_status['encrypted']:
            encrypted_buckets.append({
                'name': bucket,
                'encryption_type': encryption_status['encryption_type']
            })
            print(f"✓ {bucket}: Encrypted ({encryption_status['encryption_type']})")
        else:
            unencrypted_buckets.append(bucket)
            print(f"⚠️  {bucket}: Not encrypted")
    
    return {
        'unencrypted': unencrypted_buckets,
        'encrypted': encrypted_buckets
    }


def lambda_handler(event, context):
    """
    AWS Lambda handler function.
    
    Args:
        event: Lambda event object
        context: Lambda context object
        
    Returns:
        dict: Response with status code, body, and headers
    """
    print("Starting S3 bucket encryption check...")
    
    try:
        # Step 1: Initialize S3 client
        print("Initializing S3 client...")
        s3_client = initialize_s3_client()
        
        # Step 2: List all S3 buckets
        print("Listing all S3 buckets...")
        buckets = list_all_buckets(s3_client)
        total_buckets = len(buckets)
        print(f"Found {total_buckets} bucket(s)")
        
        if not buckets:
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'No buckets found in the account',
                    'total_buckets': 0,
                    'unencrypted_buckets': [],
                    'encrypted_buckets': []
                })
            }
        
        # Step 3: Detect buckets without encryption
        print("Checking encryption status for each bucket...")
        result = detect_unencrypted_buckets(s3_client, buckets)
        
        unencrypted_count = len(result['unencrypted'])
        encrypted_count = len(result['encrypted'])
        
        # Step 4: Print unencrypted bucket names for logging
        print("\n" + "=" * 60)
        print("UNENCRYPTED BUCKETS DETECTED")
        print("=" * 60)
        
        if result['unencrypted']:
            print(f"\n⚠️  Found {unencrypted_count} unencrypted bucket(s):\n")
            for bucket in result['unencrypted']:
                print(f"  • {bucket}")
        else:
            print("\n✓ All buckets have server-side encryption enabled!")
        
        print("\n" + "=" * 60)
        print(f"Summary: {unencrypted_count}/{total_buckets} buckets without encryption")
        print("=" * 60)
        
        # Return response
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'S3 encryption check completed successfully',
                'total_buckets': total_buckets,
                'encrypted_count': encrypted_count,
                'unencrypted_count': unencrypted_count,
                'unencrypted_buckets': result['unencrypted'],
                'encrypted_buckets': result['encrypted']
            }),
            'headers': {
                'Content-Type': 'application/json'
            }
        }
        
    except Exception as e:
        error_message = f"Error during execution: {str(e)}"
        print(error_message)
        
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Error checking S3 bucket encryption',
                'error': str(e)
            }),
            'headers': {
                'Content-Type': 'application/json'
            }
        }
