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

storeId=$(aws sso-admin list-instances      \
  --query "Instances[0].[IdentityStoreId]"  \
  --output text)
echo "Identity Store ID: $storeId"

if [ "$storeId" ]; then
  echo ""
  echo "CREATING PROVISIONERS GROUP..."
  aws identitystore create-group    \
    --identity-store-id "$storeId"  \
    --display-name "hiperium-sso-provisioners-group"   \
    --description "Contains all the users that can provision infra for Hiperium Project."
  echo "DONE!"
else
  echo "Hiperium Identity Store NOT found in IAM Identity Center..."
fi
