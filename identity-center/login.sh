#!/bin/bash

if [ -z "$AWS_PROFILE" ]; then
  echo ""
  read -r -p 'Please, enter the <AWS profile> to get access: [profile default] ' aws_profile
  if [ -z "$aws_profile" ]; then
    AWS_PROFILE='default'
    export AWS_PROFILE
  else
    AWS_PROFILE=$aws_profile
    export AWS_PROFILE
  fi
fi

aws sso login --profile "$AWS_PROFILE"

echo ""
echo "GETTING INFORMATION FROM SSO SESSION..."

accessToken=$(cat ~/.aws/sso/cache/* | jq -r '.accessToken | select( . != null )')
if [ -z "$accessToken" ]; then
  echo "Error getting the SSO Access Token..."
  exit 1
fi
reducedAccessToken=$(echo "$accessToken" | cut -c1-15)
echo "Access Token: $reducedAccessToken..."

accountId=$(aws configure get sso_account_id --profile "$AWS_PROFILE")
if [ -z "$accountId" ]; then
  echo "Error getting the SSO Account ID..."
  exit 1
fi
echo "Account ID: $accountId"

roleName=$(aws configure get sso_role_name --profile "$AWS_PROFILE")
if [ -z "$roleName" ]; then
  echo "Error getting the SSO Role Name..."
  exit 1
fi
echo "Role Name: $roleName"

roleCredentials=$(aws sso get-role-credentials  \
  --account-id "$accountId"                     \
  --role-name "$roleName"                       \
  --access-token "$accessToken"                 \
  --profile "$AWS_PROFILE"                      \
  --output json)
if [ -z "$roleCredentials" ]; then
  echo "Error getting the SSO Role Credentials..."
  exit 1
fi

echo ""
echo "CONFIGURING CLI CREDENTIALS..."

accessKeyId=$(echo "$roleCredentials" | jq -r '.roleCredentials.accessKeyId')
aws configure set aws_access_key_id "$accessKeyId" --profile "$AWS_PROFILE"

secretAccessKey=$(echo "$roleCredentials" | jq -r '.roleCredentials.secretAccessKey')
aws configure set aws_secret_access_key "$secretAccessKey" --profile "$AWS_PROFILE"

sessionToken=$(echo "$roleCredentials" | jq -r '.roleCredentials.sessionToken')
aws configure set aws_session_token "$sessionToken" --profile "$AWS_PROFILE"

echo "DONE!"
echo ""
