#!/bin/bash
set -e

echo ""
echo "GETTING INFORMATION FROM AWS. PLEASE WAIT..."

### GET PROVISIONERS GROUP ID
groupId=$(sh "$WORKING_DIR"/common/get-identity-group-id.sh)
if [ -z "$groupId" ]; then
  echo "ERROR: No Provisioners Group found in IAM Identity Center..."
  exit 1
fi
echo "- Group ID: $groupId"

echo ""
echo "DELETING PROVISIONERS GROUP..."
aws identitystore delete-group    \
  --identity-store-id "$IDENTITY_STORE_ID"  \
  --group-id "$groupId"
echo "DONE!"
