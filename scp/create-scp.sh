#!/bin/bash

if [ -z "$AWS_PROFILE" ]; then
  echo ""
  read -r -p 'Please, enter the <AWS profile> to deploy the API on AWS: [profile default] ' aws_profile
  if [ -z "$aws_profile" ]; then
    AWS_PROFILE='default'
    export AWS_PROFILE
  else
    AWS_PROFILE=$aws_profile
    export AWS_PROFILE
  fi
fi

echo ""
echo "CREATING HIPERIUM SCP..."
aws organizations create-policy                                             \
  --name hiperium-scp-policy                                             \
  --description "Deny list of services for the Hiperium organization."      \
  --content file://"$WORKING_DIR"/iam/policies/hiperium-scp-policy.json     \
  --type SERVICE_CONTROL_POLICY
echo "DONE!"
