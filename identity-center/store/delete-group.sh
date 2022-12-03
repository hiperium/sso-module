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

if [ -z "$storeId" ]; then
  echo "Hiperium Identity Store NOT found in IAM Identity Center..."
else
  groupId=$(aws identitystore list-groups   \
    --identity-store-id "$storeId"          \
    --query "Groups[?contains(DisplayName, 'hiperium-sso-provisioners-group')].[GroupId]" \
    --output text)
  echo "Group ID: $groupId"

  if [ -z "$groupId" ]; then
    echo "Provisioners Group NOT found in IAM Identity Center..."
  else
    echo ""
    echo "DELETING PROVISIONERS GROUP..."
    aws identitystore delete-group    \
      --identity-store-id "$storeId"  \
      --group-id "$groupId"
    echo "DONE!"
  fi
fi
