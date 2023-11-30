#!/bin/bash

echo ""
read -r -p 'Please, enter the <AWS Profile> to get access: [default] ' hiperium_aws_profile
if [ -z "$hiperium_aws_profile" ]; then
  hiperium_aws_profile='default'
fi

echo ""
aws sso login --profile "$hiperium_aws_profile"
echo ""

accountId=$(aws configure get sso_account_id --profile "$hiperium_aws_profile")
if [ -z "$accountId" ]; then
  echo "Error getting the SSO Account ID..."
  exit 0
fi
echo "- Account ID: $accountId"

roleName=$(aws configure get sso_role_name --profile "$hiperium_aws_profile")
if [ -z "$roleName" ]; then
  echo "Error getting the SSO Role Name..."
  exit 0
fi
echo "- Role Name: $roleName"

accessToken=$(cat ~/.aws/sso/cache/* | jq -r '.accessToken | select( . != null )')
if [ -z "$accessToken" ]; then
  echo "ERROR: There was a problem getting the SSO Access Token..."
  exit 0
fi

roleCredentials=$(aws sso get-role-credentials  \
  --account-id "$accountId"                     \
  --role-name "$roleName"                       \
  --access-token "$accessToken"                 \
  --profile "$hiperium_aws_profile"             \
  --output json)
if [ -z "$roleCredentials" ]; then
  echo "ERROR: There was a problem getting the SSO Credentials..."
  exit 0
fi

echo ""
echo "CONFIGURING AWS-CLI CREDENTIALS..."

accessKeyId=$(echo "$roleCredentials" | jq -r '.roleCredentials.accessKeyId')
aws configure set aws_access_key_id "$accessKeyId" --profile "$hiperium_aws_profile"

secretAccessKey=$(echo "$roleCredentials" | jq -r '.roleCredentials.secretAccessKey')
aws configure set aws_secret_access_key "$secretAccessKey" --profile "$hiperium_aws_profile"

sessionToken=$(echo "$roleCredentials" | jq -r '.roleCredentials.sessionToken')
aws configure set aws_session_token "$sessionToken" --profile "$hiperium_aws_profile"

echo "DONE!"
echo ""