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

rootId=$(aws organizations list-roots           \
  --query "Roots[?contains(Name, 'Root')].[Id]" \
  --output text)
if [ -z "$rootId" ]; then
  echo "Hiperium Identity Store NOT found in IAM Identity Center..."
  exit 0
fi
echo "Organization ID: $rootId"

scpId=$(aws organizations list-policies --filter SERVICE_CONTROL_POLICY \
  --query "Policies[?contains(Name, 'hiperium-scp-policy') && contains(Type, 'SERVICE_CONTROL_POLICY')].[Id]" \
  --output text)
if [ -z "$scpId" ]; then
  echo "Hiperium SCP NOT found in AWS..."
  exit 0
fi
echo "Hiperium SCP ID: $scpId"

organizationOUs=$(aws organizations list-organizational-units-for-parent \
  --parent-id "$rootId" \
  --output json)
if [ -z "$organizationOUs" ]; then
  echo "No OUs found in the Hiperium Organization."
  exit 0
fi

for ou in $(echo "$organizationOUs" | jq -r '.OrganizationalUnits[] | @base64'); do
  _jq() {
    echo "${ou}" | base64 --decode | jq -r "${1}"
  }
  ouId=$(_jq '.Id')
  ouName=$(_jq '.Name')

  if [ "$ouName" == "Suspended" ]; then
    continue
  fi

  echo ""
  read -r -p "Do you want to attach the Hiperium SCP to the ${ouName} OU? (Y/n): " yn
  if [ -z "$yn" ]; then
    yn='Y'
  fi
  case $yn in
  [Yy]*)
    echo "ATTACHING HIPERIUM SCP TO THE $ouName OU..."
    aws organizations attach-policy \
      --policy-id "$scpId"          \
      --target-id "$ouId"
    echo "DONE!"
    ;;
  *)
    echo "Your answer: No."
    ;;
  esac
done
