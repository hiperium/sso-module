#!/bin/bash
set -e

clear
echo ""
echo "CREATING HIPERIUM USER..."

echo ""
read -r -p 'Enter the user <First Name>: ' userGivenName
if [ -z "$userGivenName" ]; then
  echo "ERROR: The user <First Name> is required."
  exit 0
fi

read -r -p 'Enter the user <Last Name>: ' userFamilyName
if [ -z "$userFamilyName" ]; then
  echo "ERROR: The user <Last Name> is required."
  exit 0
fi

read -r -p 'Enter the <Username>: ' username
if [ -z "$username" ]; then
  echo "ERROR: <Username> is required."
  exit 0
fi

read -r -p 'Enter the user <Email>: ' userEmail
if [ -z "$userEmail" ]; then
  echo "ERROR: User <Email> is required."
  exit 0
fi

read -r -p 'Enter the user <Display> name: ' userDisplayName
if [ -z "$userDisplayName" ]; then
  echo "ERROR: User <Display> name is required."
  exit 0
fi

echo ""
echo "Crating User with provided info..."
aws identitystore create-user                         \
  --identity-store-id "$IDENTITY_STORE_ID"            \
  --user-name "$username"                             \
  --locale "EN"                                       \
  --timezone "America/Guayaquil"                      \
  --display-name "$userDisplayName"                   \
  --emails "Value=$userEmail,Type=Work,Primary=true"  \
  --name "Formatted=$userDisplayName,FamilyName=$userFamilyName,GivenName=$userGivenName" > /dev/null

echo "DONE!

IMPORTANT!!: The created User needs to verify his/her email before login.
             Please, go to the Organizations console and send the verification email to the created User.

             Press any key to continue...
             "
read -n 1 -s -r -p ""
