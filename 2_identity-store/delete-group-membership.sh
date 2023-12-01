#!/bin/bash
set -e

echo ""
read -r -p 'Please, enter the <Username>: ' username
if [ -z "$username" ]; then
  echo "ERROR: <Username> is required."
  exit 0
fi

echo ""
echo "GETTING INFORMATION FROM AWS. PLEASE WAIT..."

### GET PROVISIONERS GROUP ID
groupId=$(sh "$WORKING_DIR"/common/get-identity-group-id.sh)
if [ -z "$groupId" ]; then
  echo "ERROR: No Provisioners Group found in IAM Identity Center..."
  exit 0
fi
echo "- Group ID: $groupId"

### GET USER ID
userId=$(sh "$WORKING_DIR"/common/get-identity-user-id.sh "$username")
if [ -z "$userId" ]; then
  echo "ERROR: User NOT found in the IAM Identity Center..."
  exit 0
fi
echo "- User ID: $userId"

### GET MEMBERSHIP ID
groupMembershipId=$(aws identitystore get-group-membership-id   \
  --identity-store-id "$IDENTITY_STORE_ID"  \
  --group-id "$groupId"                     \
  --member-id "UserId=$userId"              \
  --query "MembershipId"                    \
  --output text)
if [ -z "$groupMembershipId" ]; then
  echo "ERROR: User Membership NOT found in the Provisioners Group..."
  exit 0
fi
echo "- Membership ID: $groupMembershipId"

echo ""
echo "DELETING PROVISIONER USER MEMBERSHIP..."
aws identitystore delete-group-membership   \
  --identity-store-id "$IDENTITY_STORE_ID"  \
  --membership-id "$groupMembershipId"
echo "DONE!"
