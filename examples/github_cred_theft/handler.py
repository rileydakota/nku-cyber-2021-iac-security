import github_detections
import boto3
import json

PIPELINE_ROLE = os.environ['PIPELINE_ROLE_ARN']
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']

def handler(event, context):
    
    if event['detail']['userIdentity']['type'] not in ['AssumedRole']:
        print('event is not called by AssumedRole - terminating')
        return
    
    if event['detail']['userIdentity']['arn'] not PIPELINE_ROLE:
        print(f'event not called by specified pipeline role ${PIPELINE_ROLE}')
        return

    caller_ip = event['detail']['sourceIPAddress']
    
    # Some Services make calls on your behalf, and use the 
    # name of the service to do it
    try:
        ipaddress.ip_address(caller_ip)
    catch:
        print('event specified IP Address is not real!')
    gh_actions_ips = github_detections.get_actions_ranges()

    sns = boto3.client('sns')

    if github_detections.ipaddress_in_networks(caller_ip, gh_actions_ips):
        print(f'{caller_ip} is a known github actions address - OK!')
    else:
        print(f'{caller_ip} isn''t a known GitHub Actions IP Address - investigate')
        sns.publish(
            TopicArn = SNS_TOPIC_ARN,
            Subject = f'GitHub Actions Pipeline Role {PIPELINE_ROLE_ARN} made API Call {event['detail']['eventName']} from an IP Address outside known GitHub Actions Ranges'
            Message = json.dumps(event['detail'])
        )

