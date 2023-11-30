#!/bin/bash
set -e

echo ""
echo "ASSIGNING INLINE <POLICY> TO <PROVISIONERS> PERMISSION-SET..."

### GET PROVISIONERS PERMISSION-SET ARN
permissionSetsArn=$(aws sso-admin list-permission-sets --instance-arn "$SSO_INSTANCE_ARN")

### ITERATE OVER PERMISSION-SETS TO FIND THE PROVISIONERS ONE
policyAssigned=false
for permissionSetArn in $(echo "$permissionSetsArn" | jq -r '.PermissionSets[]'); do
  describePermissionSet=$(aws sso-admin describe-permission-set \
    --instance-arn "$SSO_INSTANCE_ARN" \
    --permission-set-arn "$permissionSetArn")
  permissionSetName=$(echo "$describePermissionSet" | jq -r '.PermissionSet.Name')
  if [ "$permissionSetName" = "hiperium-sso-provisioners-ps" ]; then
    aws sso-admin put-inline-policy-to-permission-set   \
      --instance-arn "$SSO_INSTANCE_ARN"                \
      --permission-set-arn "$permissionSetArn"          \
      --inline-policy "$(cat "$WORKING_DIR"/templates/iam/policies/hiperium-iam-provisioners-policy.json)"
    echo "Done!"
    policyAssigned=true
    break
  fi
done

if [ "$policyAssigned" == false ]; then
  echo ""
  echo "NO INLINE POLICY WAS FOUND TO ASSIGN THE PERMISSION-SET..."
fi
