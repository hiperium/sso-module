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

instanceArn=$(aws sso-admin list-instances \
  --query "Instances[0].[InstanceArn]" \
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

storeId=$(aws sso-admin list-instances \
  --query "Instances[0].[IdentityStoreId]" \
  --output text)
if [ -z "$storeId" ]; then
  echo "Hiperium Identity Store NOT found in IAM Identity Center..."
  exit 0
fi
echo "Identity Store ID: $storeId"

groupId=$(aws identitystore list-groups \
  --identity-store-id "$storeId" \
  --query "Groups[?contains(DisplayName, 'hiperium-sso-provisioners-group')].[GroupId]" \
  --output text)
if [ -z "$groupId" ]; then
  echo "Provisioners Group NOT found in IAM Identity Center..."
  exit 0
fi
echo "Group ID: $groupId"

# GET ACTUAL ACCOUNT-ID FOR ASSIGNMENT EXCLUSION
actualAccountId=$(aws sts get-caller-identity --profile "$AWS_PROFILE" --query "Account" --output text)

echo ""
echo "Getting active accounts from the Organization..."
listAccounts=$(aws organizations list-accounts --query "Accounts[?contains(Status, 'ACTIVE')]" --output json)
for account in $(echo "$listAccounts" | jq -r '.[] | @base64'); do
  _jq() {
    echo "${account}" | base64 --decode | jq -r "${1}"
  }
  accountId=$(_jq '.Id')
  accountName=$(_jq '.Name')

  if [ "$accountId" == "$actualAccountId" ]; then
    continue
  fi

  echo ""
  read -r -p "Do you want to assign the 'Provisioners' Permission-Set to Account '${accountName}'? (y/N): " yn
  if [ -z "$yn" ]; then
    yn='N'
  fi

  case $yn in
  [Yy]*)
    echo "Assigning 'Provisioners' Permission-Set to Account '$accountName'..."
    aws sso-admin create-account-assignment               \
      --instance-arn "$instanceArn"                       \
      --target-type AWS_ACCOUNT                           \
      --target-id "$accountId"                            \
      --permission-set-arn "$provisionersPermissionArn"   \
      --principal-type GROUP                              \
      --principal-id "$groupId"
    echo "DONE!"
    ;;
  *)
    echo "Your answer: No."
    echo "DONE."
    ;;
  esac
done
