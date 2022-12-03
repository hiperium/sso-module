#!/bin/bash

if [ -z "$AWS_PROFILE" ]; then
  echo ""
  read -r -p 'Please, enter the <AWS profile> to deploy the API on AWS: [profile default] ' aws_profile
  if [ -z "$aws_profile" ]; then
    AWS_PROFILE='default'
    export AWS_PROFILE
  else
    AWS_PROFILE=$aws_profile
    export AWS_PROFILE
  fi
fi

echo ""
echo "GETTING INFO FROM THE ORGANIZATION..."

instanceArn=$(aws sso-admin list-instances  \
    --query "Instances[0].[InstanceArn]"    \
    --output text)
echo "Instance ARN: $instanceArn"

if [ -z "$instanceArn" ]; then
  echo "No IAM Identity Center Instance found in AWS..."
else
  echo ""
  echo "CREATING PERMISSION-SET FOR PROVISIONERS..."
  aws sso-admin create-permission-set         \
    --instance-arn "$instanceArn"             \
    --name "hiperium-sso-provisioners-ps"     \
    --session-duration "PT8H"                 \
    --description "Permission-set for Hiperium provisioners" \
    --relay-state "https://us-east-1.console.aws.amazon.com/console/home"
    echo "DONE!"
fi
