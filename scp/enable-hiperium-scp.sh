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

rootId=$(aws organizations list-roots           \
  --query "Roots[?contains(Name, 'Root')].[Id]" \
  --output text)
echo "Organization ID: $rootId"

if [ "$rootId" ]; then
  echo ""
  echo "ENABLING ORGANIZATIONS SCP..."
  aws organizations enable-policy-type                \
    --root-id "$rootId"                               \
    --policy-type SERVICE_CONTROL_POLICY
  echo "DONE!"
else
  echo "Hiperium Identity Store NOT found in IAM Identity Center..."
fi
