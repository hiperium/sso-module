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
if [ -z "$storeId" ]; then
  echo "Hiperium Identity Store NOT found in IAM Identity Center..."
  exit 0
fi
echo "Identity Store ID: $storeId"

groupId=$(aws identitystore list-groups \
  --identity-store-id "$storeId"        \
  --query "Groups[?contains(DisplayName, 'hiperium-sso-provisioners-group')].[GroupId]" \
  --output text)
if [ -z "$groupId" ]; then
  echo "Provisioners Group NOT found in IAM Identity Center..."
  exit 0
fi
echo "Group ID: $groupId"

echo ""
read -r -p 'Please, enter the username to be assigned to Provisioners Group: [default sandbox] ' username
if [ -z "$username" ]; then
  username='sandbox'
fi

userId=$(aws identitystore list-users \
  --identity-store-id "$storeId"      \
  --query "Users[?contains(UserName, '$username')].[UserId]" \
  --output text)
echo "User ID: $userId"
if [ -z "$userId" ]; then
  echo "User NOT found in IAM Identity Center..."
  exit 0
fi

echo ""
echo "ASSIGNING USER TO PROVISIONERS GROUP..."
aws identitystore create-group-membership   \
  --identity-store-id "$storeId"            \
  --group-id "$groupId"                     \
  --member-id "UserId=$userId"
echo "DONE!"
