import zipfile
import os

lambda_code = """
import boto3

def lambda_handler(event, context):
    account_id = boto3.client('sts').get_caller_identity()['Account']
    config_role = 'guardduty_security_config-role-jpyjbsz5'
    config_bucket = 'guardduty-global-security-config-bucket'

    ec2 = boto3.client('ec2')
    regions = [r['RegionName'] for r in ec2.describe_regions()['Regions']]

    for region in regions:
        print(f"🔄 Processing region: {region}")

        # Enable GuardDuty
        gd = boto3.client('guardduty', region_name=region)
        try:
            detector_id = gd.create_detector(Enable=True)['DetectorId']
            print(f"✅ GuardDuty enabled in {region} (Detector ID: {detector_id})")
        except gd.exceptions.BadRequestException:
            print(f"⚠️ GuardDuty may already be enabled in {region}")

        # Enable AWS Config
        config = boto3.client('config', region_name=region)
        recorders = config.describe_configuration_recorders()['ConfigurationRecorders']
        if not recorders:
            config.put_configuration_recorder(
                ConfigurationRecorder={
                    'name': 'default',
                    'roleARN': f'arn:aws:iam::{account_id}:role/{config_role}',
                    'recordingGroup': {
                        'allSupported': True,
                        'includeGlobalResourceTypes': True
                    }
                }
            )
            config.put_delivery_channel(
                DeliveryChannel={
                    'name': 'default',
                    's3BucketName': config_bucket
                }
            )
            config.start_configuration_recorder(ConfigurationRecorderName='default')
            print(f"✅ AWS Config enabled in {region}")
        else:
            print(f"⚠️ AWS Config already set in {region}")

        # Enable Security Hub
        sh = boto3.client('securityhub', region_name=region)
        try:
            sh.enable_security_hub()
            print(f"✅ Security Hub enabled in {region}")
        except:
            print(f"⚠️ Security Hub may already be enabled in {region}")

        try:
            sh.enable_standards(
                StandardsSubscriptionRequests=[
                    {
                        'StandardsArn': 'arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0'
                    }
                ]
            )
            print(f"✅ CIS Benchmark enabled in {region}")
        except:
            print(f"⚠️ CIS Benchmark may already be enabled in {region}")

    print("🎉 Multi-region security setup complete!")
"""

file_name = "lambda_function.py"
with open(file_name, "w", encoding="utf-8") as f:
    f.write(lambda_code.strip())

zip_file_name = "multi_region_security_setup.zip"
with zipfile.ZipFile(zip_file_name, "w", zipfile.ZIP_DEFLATED) as zipf:
    zipf.write(file_name)

os.remove(file_name)
print(f"✅ Created: {zip_file_name}")
