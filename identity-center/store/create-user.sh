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
echo "GETTING INFO FROM THE ORGANIZATION..."

storeId=$(aws sso-admin list-instances      \
  --query "Instances[0].[IdentityStoreId]"  \
  --output text)
echo "Identity Store ID: $storeId"
if [ -z "$storeId" ]; then
  echo "Hiperium Identity Store NOT found in IAM Identity Center..."
  exit 1
fi

echo ""
read -r -p 'Please, enter the username: [default sandbox] ' username
if [ -z "$username" ]; then
  username='sandbox'
fi

read -r -p 'Please, enter the user email: [default sandbox@example.com] ' userEmail
if [ -z "$userEmail" ]; then
  userEmail='sandbox@example.com'
fi

read -r -p 'Please, enter the First name: ' userGivenName
if [ -z "$userGivenName" ]; then
  userGivenName='User'
fi

read -r -p 'Please, enter the Last name: ' userFamilyName
if [ -z "$userFamilyName" ]; then
  userFamilyName='Sandbox'
fi

read -r -p 'Please, enter the Display name: ' userDisplayName
if [ -z "$userDisplayName" ]; then
  userDisplayName='Sandbox User'
fi

echo ""
echo "CREATING USER..."
aws identitystore create-user         \
  --identity-store-id "$storeId"      \
  --user-name "$username"             \
  --locale "EN"                       \
  --timezone "America/Guayaquil"      \
  --display-name "$userDisplayName"   \
  --emails "Value=$userEmail,Type=Work,Primary=true" \
  --name "Formatted=$userDisplayName,FamilyName=$userFamilyName,GivenName=$userGivenName"

echo "DONE!"
echo ""
echo "IMPORTANT: The created User needs to verify the email address before login. Please, go to the Organizations console and send the verification email to the User."

echo ""
read -r -p 'Press [ENTER] to continue...' enter
