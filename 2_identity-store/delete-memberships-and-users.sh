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
echo "DELETING MEMBERSHIPS AND USERS FROM <PROVISIONERS> GROUP..."

### GET MEMBERSHIPS
groupMemberships=$(aws identitystore list-group-memberships \
  --identity-store-id "$IDENTITY_STORE_ID"                  \
  --group-id "$groupId")
numberOfMembers=$(echo "$groupMemberships" | jq -r '.GroupMemberships | length')
if [ "$numberOfMembers" -eq 0 ]; then
  echo "ERROR: No members found in Provisioners Group..."
  exit 0
fi
echo "- Number of members: $numberOfMembers"

### ITERATE OVER MEMBERSHIPS TO DELETE USERS
for groupMembership in $(echo "$groupMemberships" | jq -r '.GroupMemberships[] | @base64'); do
  _jq() {
    echo "${groupMembership}" | base64 --decode | jq -r "${1}"
  }
  membershipId=$(_jq '.MembershipId')
  echo ""
  echo "- Deleting Membership: $membershipId..."
  aws identitystore delete-group-membership   \
    --identity-store-id "$IDENTITY_STORE_ID"  \
    --membership-id "$membershipId"

  memberId=$(_jq '.MemberId | @base64')
  _jq() {
    echo "${memberId}" | base64 --decode | jq -r "${1}"
  }
  userId=$(_jq '.UserId')
  echo "- Deleting User: $userId..."
  aws identitystore delete-user               \
    --identity-store-id "$IDENTITY_STORE_ID"  \
    --user-id "$userId"
done

echo "DONE!"
