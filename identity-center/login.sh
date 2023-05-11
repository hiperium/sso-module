#!/bin/bash

echo ""
read -r -p 'Please, enter the <AWS profile> to get access: [profile default] ' hiperium_aws_profile
if [ -z "$hiperium_aws_profile" ]; then
  hiperium_aws_profile='default'
fi

echo ""
aws sso login --profile "$hiperium_aws_profile"

echo ""
echo "GETTING INFORMATION FROM SSO SESSION..."
echo ""

accessToken=$(cat ~/.aws/sso/cache/* | jq -r '.accessToken | select( . != null )')
if [ -z "$accessToken" ]; then
  echo "Error getting the SSO Access Token..."
  exit 1
fi
echo "Access Token: $(echo "$accessToken" | cut -c1-20)..."

accountId=$(aws configure get sso_account_id --profile "$hiperium_aws_profile")
if [ -z "$accountId" ]; then
  echo "Error getting the SSO Account ID..."
  exit 1
fi
echo "Account ID: $accountId"

roleName=$(aws configure get sso_role_name --profile "$hiperium_aws_profile")
if [ -z "$roleName" ]; then
  echo "Error getting the SSO Role Name..."
  exit 1
fi
echo "Role Name: $roleName"

roleCredentials=$(aws sso get-role-credentials  \
  --account-id "$accountId"                     \
  --role-name "$roleName"                       \
  --access-token "$accessToken"                 \
  --profile "$hiperium_aws_profile"                      \
  --output json)
if [ -z "$roleCredentials" ]; then
  echo "Error getting the SSO Role Credentials..."
  exit 1
fi

echo ""
echo "CONFIGURING CLI CREDENTIALS..."

accessKeyId=$(echo "$roleCredentials" | jq -r '.roleCredentials.accessKeyId')
aws configure set aws_access_key_id "$accessKeyId" --profile "$hiperium_aws_profile"

secretAccessKey=$(echo "$roleCredentials" | jq -r '.roleCredentials.secretAccessKey')
aws configure set aws_secret_access_key "$secretAccessKey" --profile "$hiperium_aws_profile"

sessionToken=$(echo "$roleCredentials" | jq -r '.roleCredentials.sessionToken')
aws configure set aws_session_token "$sessionToken" --profile "$hiperium_aws_profile"

echo "DONE!"
echo ""
