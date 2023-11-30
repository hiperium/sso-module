#!/bin/bash
set -e

echo ""
read -r -p 'Please, enter the username: ' username
if [ -z "$username" ]; then
  echo "ERROR: Username is required..."
  exit 0
fi

### GET USER ID
userId=$(sh "$WORKING_DIR"/common/get-identity-user-id.sh "$username")
if [ -z "$userId" ]; then
  echo "ERROR: User NOT found in the IAM Identity Center..."
  exit 0
fi
echo "- User ID: $userId"

echo ""
echo "DELETING USER..."
aws identitystore delete-user     \
  --identity-store-id "$IDENTITY_STORE_ID"  \
  --user-id "$userId"
echo "DONE!"
