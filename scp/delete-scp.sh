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

scpId=$(aws organizations list-policies --filter SERVICE_CONTROL_POLICY \
  --query "Policies[?contains(Name, 'hiperium-scp-policy') && contains(Type, 'SERVICE_CONTROL_POLICY')].[Id]" \
  --output text)
echo "Hiperium SCP ID: $scpId"

if [ "$scpId" ]; then
  echo ""
  echo "DELETING HIPERIUM SCP..."
  aws organizations delete-policy                             \
    --policy-id "$scpId"
  echo "DONE!"
else
  echo "Hiperium Identity Store NOT found in IAM Identity Center..."
fi



