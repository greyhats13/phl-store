# import boto3
# import os

# ec2_client = boto3.client('ec2')

# def lambda_handler(event, context):
#     action = event['action']
#     instance_ids =  os.environ['INSTANCE_IDS'].split(',')

#     if action == 'start':
#         ec2_client.start_instances(InstanceIds=instance_ids)
#         return f"Starting instances: {instance_ids}"
#     elif action == 'stop':
#         ec2_client.stop_instances(InstanceIds=instance_ids)
#         return f"Stopping instances: {instance_ids}"
#     else:
#         return f"Invalid action: {action}"

# import boto3

# ec2 = boto3.client('ec2')

# def lambda_handler(event, context):
#     volume = ec2.describe_volumes(Filters=[{'Name': 'status', 'Values': ['available']}])['Volumes']
#     volume_id = volume['VolumeId']
#     print(f"Deleting volume {volume_id}")
#     ec2.delete_volume(VolumeId=volume_id)

import boto3
import psutil

cloudwatch = boto3.client('cloudwatch')

def lambda_handler(event, context):
    memory_usage = psutil.virtual_memory().percent
    cloudwatch.put_metric_data(
        Namespace='CustomMetrics',
        MetricData=[
            {
                'MetricName': 'MemoryUtilization',
                'Dimensions': [
                    {
                        'Name': 'InstanceID',
                        'Value': 'i-0d8b2b7d3e0b4e7b2'
                    },
                ],
                'Unit': 'Percent',
                'Value': memory_usage
            },
        ]
    )