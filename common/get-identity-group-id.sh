#!/bin/bash
set -e

groupId=$(aws identitystore list-groups     \
  --identity-store-id "$IDENTITY_STORE_ID"  \
  --query "Groups[?contains(DisplayName, 'hiperium-sso-provisioners-group')].[GroupId]" \
  --output text)

echo "$groupId"
