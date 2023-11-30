#!/bin/bash
set -e

username=$1

userId=$(aws identitystore list-users         \
  --identity-store-id "$IDENTITY_STORE_ID"    \
  --query "Users[?contains(UserName, '$username')].[UserId]" \
  --output text)

echo "$userId"
