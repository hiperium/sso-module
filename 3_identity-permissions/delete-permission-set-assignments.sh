#!/bin/bash
set -e

echo ""
echo "GETTING INFORMATION FROM AWS. PLEASE WAIT..."

### GET PROVISIONERS GROUP ID
groupId=$(sh "$WORKING_DIR"/common/get-identity-group-id.sh)
if [ -z "$groupId" ]; then
  echo "ERROR: No Provisioners Group found in IAM Identity Center..."
  exit 0
fi
echo "- Group ID: $groupId"

echo ""
echo "DELETING PERMISSION-SET FROM ASSIGNED ACCOUNTS..."

### GET PROVISIONERS PERMISSION-SET ARN
permissionSetsArn=$(aws sso-admin list-permission-sets --instance-arn "$SSO_INSTANCE_ARN")

### ITERATE OVER PERMISSION-SETS TO FIND PROVISIONERS PERMISSION-SET
for permissionSetArn in $(echo "$permissionSetsArn" | jq -r '.PermissionSets[]'); do
  describePermissionSet=$(aws sso-admin describe-permission-set \
    --instance-arn "$SSO_INSTANCE_ARN" \
    --permission-set-arn "$permissionSetArn")
  permissionSetName=$(echo "$describePermissionSet" | jq -r '.PermissionSet.Name')

  if [ "$permissionSetName" = "sso-city-provisioners-ps" ]; then
    provisionersPermissionArn="$permissionSetArn"
    break
  fi
done

### CHECK IF PROVISIONERS PERMISSION-SET WAS FOUND
if [ -z "$provisionersPermissionArn" ]; then
  echo "ERROR: Provisioners Permission-Set NOT found in IAM Identity Center..."
  exit 0
fi
echo "- Provisioners Permission-Set ARN: $provisionersPermissionArn"

### GET PROVISIONED ACCOUNTS FOR PROVISIONERS PERMISSION-SET
provisionedAccounts=$(aws sso-admin list-accounts-for-provisioned-permission-set \
  --instance-arn "$SSO_INSTANCE_ARN" \
  --permission-set-arn "$provisionersPermissionArn")
numberOfProvisionedAccounts=$(echo "$provisionedAccounts" | jq -r '.AccountIds | length')
if [ "$numberOfProvisionedAccounts" -eq 0 ]; then
  echo "ERROR: No provisioned accounts found to delete..."
  exit 0
fi
echo "- Number of provisioned accounts: $numberOfProvisionedAccounts"

### DELETE PROVISIONERS PERMISSION-SET ASSIGNMENT FOR EACH PROVISIONED ACCOUNT
echo ""
for accountId in $(echo "$provisionedAccounts" | jq -r '.AccountIds[]'); do
  echo "- Deleting Assignment for Account: $accountId"
  aws sso-admin delete-account-assignment               \
    --instance-arn "$SSO_INSTANCE_ARN"                  \
    --target-type AWS_ACCOUNT                           \
    --target-id "$accountId"                            \
    --permission-set-arn "$provisionersPermissionArn"   \
    --principal-type GROUP                              \
    --principal-id "$groupId" > /dev/null
done
echo "DONE!"
