#!/bin/bash
set -e

echo ""
echo "DELETING <PROVISIONERS> PERMISSION-SET..."

### GET PERMISSION-SET ARN
permissionSetsArn=$(aws sso-admin list-permission-sets --instance-arn "$SSO_INSTANCE_ARN")

### ITERATE OVER PERMISSION-SETS
permissionSetDeleted=false
for permissionSetArn in $(echo "$permissionSetsArn" | jq -r '.PermissionSets[]'); do
  describePermissionSet=$(aws sso-admin describe-permission-set \
    --instance-arn "$SSO_INSTANCE_ARN" \
    --permission-set-arn "$permissionSetArn")
  permissionSetName=$(echo "$describePermissionSet" | jq -r '.PermissionSet.Name')
  if [ "$permissionSetName" = "hiperium-sso-provisioners-ps" ]; then
    aws sso-admin delete-permission-set           \
      --instance-arn "$SSO_INSTANCE_ARN"               \
      --permission-set-arn "$permissionSetArn"
    permissionSetDeleted=true
    break
  fi
done

if [ "$permissionSetDeleted" == false ]; then
  echo ""
  echo "NO PERMISSION-SET FOUND TO DELETE..."
else
  echo "DONE!"
fi
