#!/bin/bash
set -e

echo ""
echo "GETTING INFORMATION FROM AWS. PLEASE WAIT..."

### GET PERMISSION-SET ARN
permissionSetsArn=$(aws sso-admin list-permission-sets --instance-arn "$SSO_INSTANCE_ARN")

### ITERATE OVER PERMISSION-SETS
permissionSetUpdated=false
for permissionSetArn in $(echo "$permissionSetsArn" | jq -r '.PermissionSets[]'); do
  describePermissionSet=$(aws sso-admin describe-permission-set \
    --instance-arn "$SSO_INSTANCE_ARN" \
    --permission-set-arn "$permissionSetArn")
  permissionSetName=$(echo "$describePermissionSet" | jq -r '.PermissionSet.Name')
  if [ "$permissionSetName" = "sso-city-provisioners-ps" ]; then
    echo ""
    echo "Updating <provisioners> Permission-Set..."
    aws sso-admin update-permission-set           \
      --instance-arn "$SSO_INSTANCE_ARN"          \
      --permission-set-arn "$permissionSetArn"    \
      --session-duration "PT8H"                   \
      --description "Permission-Set updated for application provisioners"   \
      --relay-state "https://us-east-1.console.aws.amazon.com/console/home"
    echo "Done!"
    permissionSetUpdated=true
    break
  fi
done

if [ "$permissionSetUpdated" == false ]; then
  echo ""
  echo "NO PERMISSION-SET FOUND TO UPDATE..."
  exit 1
fi
