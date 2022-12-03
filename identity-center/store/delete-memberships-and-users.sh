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

groupMemberships=$(aws identitystore list-group-memberships \
  --identity-store-id "$storeId" \
  --group-id "$groupId")
numberOfMembers=$(echo "$groupMemberships" | jq -r '.GroupMemberships | length')
if [ "$numberOfMembers" -eq 0 ]; then
  echo "No members found in Provisioners Group..."
  exit 0
fi
echo "Number of members: $numberOfMembers"

echo ""
echo "DELETING MEMBERSHIPS AND USERS FROM PROVISIONERS GROUP..."
for groupMembership in $(echo "$groupMemberships" | jq -r '.GroupMemberships[] | @base64'); do
  _jq() {
    echo "${groupMembership}" | base64 --decode | jq -r "${1}"
  }
  membershipId=$(_jq '.MembershipId')
  echo "Removing Membership ID: $membershipId..."
  aws identitystore delete-group-membership \
    --identity-store-id "$storeId"          \
    --membership-id "$membershipId"

  memberId=$(_jq '.MemberId | @base64')
  _jq() {
    echo "${memberId}" | base64 --decode | jq -r "${1}"
  }
  userId=$(_jq '.UserId')
  echo "Removing User ID: $userId..."
  aws identitystore delete-user     \
    --identity-store-id "$storeId"  \
    --user-id "$userId"
done
echo "DONE!"


