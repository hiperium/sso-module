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

instanceArn=$(aws sso-admin list-instances  \
  --query "Instances[0].[InstanceArn]"      \
  --output text)
if [ -z "$instanceArn" ]; then
  echo "No IAM Identity Center Instance found in AWS..."
  exit 0
fi
echo "Instance ARN: $instanceArn"

permissionSetsArn=$(aws sso-admin list-permission-sets \
  --instance-arn "$instanceArn")
for permissionSetArn in $(echo "$permissionSetsArn" | jq -r '.PermissionSets[]'); do
  describePermissionSet=$(aws sso-admin describe-permission-set \
    --instance-arn "$instanceArn" \
    --permission-set-arn "$permissionSetArn")
  permissionSetName=$(echo "$describePermissionSet" | jq -r '.PermissionSet.Name')

  if [ "$permissionSetName" = "hiperium-sso-provisioners-ps" ]; then
    provisionersPermissionArn="$permissionSetArn"
    break
  fi
done
if [ -z "$provisionersPermissionArn" ]; then
  echo "Provisioners Permission-Set NOT found in IAM Identity Center..."
  exit 0
fi
echo "Provisioners Permission-Set ARN: $provisionersPermissionArn"

provisionedAccounts=$(aws sso-admin list-accounts-for-provisioned-permission-set \
  --instance-arn "$instanceArn" \
  --permission-set-arn "$provisionersPermissionArn")
numberOfProvisionedAccounts=$(echo "$provisionedAccounts" | jq -r '.AccountIds | length')
if [ "$numberOfProvisionedAccounts" -eq 0 ]; then
  echo "No provisioned accounts found to delete..."
  exit 0
fi
echo "Number of provisioned accounts found: $numberOfProvisionedAccounts"

echo ""
echo "DELETING PERMISSION SET FOR THE ASSIGNMENT ACCOUNTS..."
for accountId in $(echo "$provisionedAccounts" | jq -r '.AccountIds[]'); do
  echo "Account ID: $accountId"
  aws sso-admin delete-account-assignment               \
    --instance-arn "$instanceArn"                       \
    --target-type AWS_ACCOUNT                           \
    --target-id "$accountId"                            \
    --permission-set-arn "$provisionersPermissionArn"   \
    --principal-type GROUP                              \
    --principal-id "$groupId"
done

echo "DONE!"
