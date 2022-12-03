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
  --query "Instances[0].[InstanceArn]"      \
  --output text)
echo "Instance ARN: $instanceArn"

if [ -z "$instanceArn" ]; then
  echo "No IAM Identity Center Instance found in AWS..."
else
  permissionSetDeleted=false
  permissionSetsArn=$(aws sso-admin list-permission-sets \
    --instance-arn "$instanceArn")

  for permissionSetArn in $(echo "$permissionSetsArn" | jq -r '.PermissionSets[]'); do
    describePermissionSet=$(aws sso-admin describe-permission-set \
      --instance-arn "$instanceArn" \
      --permission-set-arn "$permissionSetArn")
    permissionSetName=$(echo "$describePermissionSet" | jq -r '.PermissionSet.Name')

    if [ "$permissionSetName" = "hiperium-sso-provisioners-ps" ]; then
      echo ""
      echo "DELETING PERMISSION-SET FOR PROVISIONERS..."
      aws sso-admin delete-permission-set           \
        --instance-arn "$instanceArn"               \
        --permission-set-arn "$permissionSetArn"
      echo "DONE!"
      permissionSetDeleted=true
      break
    fi
  done

  if [ "$permissionSetDeleted" == false ]; then
    echo ""
    echo "NO PERMISSION-SET FOUND TO DELETE..."
  fi
fi
