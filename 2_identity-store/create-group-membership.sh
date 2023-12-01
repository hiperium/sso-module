#!/bin/bash
set -e

echo ""
read -r -p 'Enter the <Username> to assign to <Provisioners> group: ' username
if [ -z "$username" ]; then
  echo "ERROR: Username is required."
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

echo ""
echo "ASSIGNING USER TO PROVISIONERS GROUP..."
aws identitystore create-group-membership       \
  --identity-store-id "$IDENTITY_STORE_ID"      \
  --group-id "$groupId"                         \
  --member-id "UserId=$userId" > /dev/null
echo "DONE!"
