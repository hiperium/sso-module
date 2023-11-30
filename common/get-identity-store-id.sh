#!/bin/bash
set -e

storeId=$(aws sso-admin list-instances      \
  --query "Instances[0].[IdentityStoreId]"  \
  --output text | grep -v None)

echo "$storeId"
