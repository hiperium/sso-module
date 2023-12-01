#!/bin/bash
set -e

echo ""
echo "CREATING PERMISSION-SET FOR PROVISIONERS..."
aws sso-admin create-permission-set                         \
  --instance-arn "$SSO_INSTANCE_ARN"                        \
  --name "sso-city-provisioners-ps"                         \
  --session-duration "PT8H"                                 \
  --description "Permission-set for Hiperium provisioners"  \
  --relay-state "https://us-east-1.console.aws.amazon.com/console/home" > /dev/null
  echo "DONE!"
