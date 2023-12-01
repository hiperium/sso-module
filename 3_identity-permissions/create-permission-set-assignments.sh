#!/bin/bash
set -e

echo ""
echo "GETTING INFORMATION FROM AWS. PLEASE WAIT..."

### GET PROVISIONERS GROUP ID
groupId=$(sh "$WORKING_DIR"/common/get-identity-group-id.sh)
if [ -z "$groupId" ]; then
  echo "ERROR: Provisioners Group NOT found in IAM Identity Center..."
  exit 0
fi
echo "- Group ID: $groupId"

echo ""
echo "FINDING <PROVISIONERS> PERMISSION-SET..."

### GET PROVISIONERS PERMISSION-SET ARN
permissionSetsArn=$(aws sso-admin list-permission-sets --instance-arn "$SSO_INSTANCE_ARN")

### ITERATE OVER PERMISSION-SETS TO GET PROVISIONERS PERMISSION-SET ARN
for permissionSetArn in $(echo "$permissionSetsArn" | jq -r '.PermissionSets[]'); do
  describePermissionSet=$(aws sso-admin describe-permission-set \
    --instance-arn "$SSO_INSTANCE_ARN"  \
    --permission-set-arn "$permissionSetArn")
  permissionSetName=$(echo "$describePermissionSet" | jq -r '.PermissionSet.Name')
  if [ "$permissionSetName" = "sso-city-provisioners-ps" ]; then
    provisionersPermissionArn="$permissionSetArn"
    break
  fi
done
if [ -z "$provisionersPermissionArn" ]; then
  echo "ERROR: <provisioners> Permission-Set NOT found..."
  exit 0
fi
echo "- Permission-Set: $provisionersPermissionArn"

# GET ACTUAL ACCOUNT-ID FOR ASSIGNMENT
actualAccountId=$(aws sts get-caller-identity   \
  --profile "$AWS_PROFILE"                      \
  --query "Account"                             \
  --output text)
if [ -z "$actualAccountId" ]; then
  echo "ERROR: No AWS Account ID found for the assignment..."
  exit 0
fi

clear
echo ""
echo "PROVISIONERS PERMISSION-SET ASSIGNMENT TO ACCOUNTS..."

### GET LIST OF ACCOUNTS
listAccounts=$(aws organizations list-accounts --query "Accounts[?contains(Status, 'ACTIVE')]" --output json)

### ITERATE OVER ACCOUNTS TO ASSIGN PERMISSION-SET
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
    echo "Assigning Permission-Set..."
    aws sso-admin create-account-assignment               \
      --instance-arn "$SSO_INSTANCE_ARN"                  \
      --target-type AWS_ACCOUNT                           \
      --target-id "$accountId"                            \
      --permission-set-arn "$provisionersPermissionArn"   \
      --principal-type GROUP                              \
      --principal-id "$groupId" > /dev/null
    echo "Done!"
    ;;
  *)
    echo "Your answer: No."
    echo "DONE."
    ;;
  esac
done
