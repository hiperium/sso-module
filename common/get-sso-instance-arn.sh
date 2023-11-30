#!/bin/bash
set -e

instanceArn=$(aws sso-admin list-instances  \
  --query "Instances[0].[InstanceArn]"      \
  --output text | grep -v None)

echo "$instanceArn"
