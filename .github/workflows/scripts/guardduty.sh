#!/bin/bash

# Set the S3 bucket name for AWS Config (must be global or created in each region)
CONFIG_S3_BUCKET="guardduty-global-security-config-bucket"
CONFIG_ROLE_NAME="devopsEcs"

# Get all regions
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

for REGION in $REGIONS; do
  echo "🔄 Processing region: $REGION"

  ### 1. Enable GuardDuty
  DETECTOR_ID=$(aws guardduty create-detector --enable --region "$REGION" --query 'DetectorId' --output text 2>/dev/null)
  if [ -n "$DETECTOR_ID" ]; then
    echo "✅ GuardDuty enabled in $REGION (Detector ID: $DETECTOR_ID)"
  else
    echo "⚠️ GuardDuty may already be enabled in $REGION"
  fi

  ### 2. Enable AWS Config
  # Check if the recorder exists
  RECORDER_EXISTS=$(aws configservice describe-configuration-recorders --region "$REGION" --query "ConfigurationRecorders[*].name" --output text)

  if [ -z "$RECORDER_EXISTS" ]; then
    aws configservice put-configuration-recorder \
      --region "$REGION" \
      --configuration-recorder "name=default,roleARN=arn:aws:iam::$ACCOUNT_ID:role/$CONFIG_ROLE_NAME,recordingGroup={allSupported=true,includeGlobalResourceTypes=true}"

    aws configservice put-delivery-channel \
      --region "$REGION" \
      --delivery-channel "name=default,s3BucketName=$CONFIG_S3_BUCKET"

    aws configservice start-configuration-recorder \
      --region "$REGION" \
      --configuration-recorder-name "default"

    echo "✅ AWS Config enabled in $REGION"
  else
    echo "⚠️ AWS Config already set in $REGION"
  fi

  ### 3. Enable Security Hub & CIS Benchmark
  aws securityhub enable-security-hub --region "$REGION" >/dev/null 2>&1 && echo "✅ Security Hub enabled in $REGION"

  aws securityhub enable-standards \
    --region "$REGION" \
    --standards-subscription-requests '[{"StandardsArn":"arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"}]' >/dev/null 2>&1 \
    && echo "✅ CIS Benchmark enabled in $REGION"

  echo "-----------------------------"

done

echo "🎉 Multi-region security setup complete!"

