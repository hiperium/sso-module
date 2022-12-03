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
  echo "Hiperium Identity Store NOT found in the IAM Identity Center..."
  exit 0
fi
echo "Identity Store ID: $storeId"

echo ""
read -r -p 'Please, enter the username: [default sandbox] ' username
if [ -z "$username" ]; then
  username='sandbox'
fi

userId=$(aws identitystore list-users \
  --identity-store-id "$storeId"      \
  --query "Users[?contains(UserName, '$username')].[UserId]" \
  --output text)
if [ -z "$userId" ]; then
  echo "User NOT found in the IAM Identity Center..."
  exit 0
fi
echo "User ID found: $userId"

echo ""
echo "DELETING USER..."
aws identitystore delete-user     \
  --identity-store-id "$storeId"  \
  --user-id "$userId"
echo "DONE!"
