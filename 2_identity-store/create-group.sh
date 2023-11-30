#!/bin/bash
set -e

echo ""
echo "CREATING PROVISIONERS GROUP..."
aws identitystore create-group                        \
  --identity-store-id "$IDENTITY_STORE_ID"            \
  --display-name "hiperium-sso-provisioners-group"    \
  --description "Contains all the users that can provision infra for Hiperium Project."
echo "DONE!"
