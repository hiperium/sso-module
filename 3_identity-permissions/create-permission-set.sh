#!/bin/bash
set -e

echo ""
echo "CREATING PERMISSION-SET FOR PROVISIONERS..."
aws sso-admin create-permission-set         \
  --instance-arn "$SSO_INSTANCE_ARN"        \
  --name "hiperium-sso-provisioners-ps"     \
  --session-duration "PT8H"                 \
  --description "Permission-set for Hiperium provisioners" \
  --relay-state "https://us-east-1.console.aws.amazon.com/console/home"
  echo "DONE!"
