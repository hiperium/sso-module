#!/bin/bash
set -e

echo ""
echo "GETTING INFORMATION FROM AWS. PLEASE WAIT..."

### GETTING HIPERIUM SCP ID
scpId=$(aws organizations list-policies --filter SERVICE_CONTROL_POLICY \
  --query "Policies[?contains(Name, 'hiperium-scp-policy') && contains(Type, 'SERVICE_CONTROL_POLICY')].[Id]" \
  --output text)
if [ -z "$scpId" ]; then
  echo "ERROR: Hiperium SCP NOT found in AWS..."
  exit 1
fi
echo "- Hiperium SCP ID: $scpId"

echo ""
echo "ATTACHING HIPERIUM SCP TO OUs..."

### GETTING OUs
organizationOUs=$(aws organizations list-organizational-units-for-parent \
  --parent-id "$ORG_ROOT_ID" \
  --output json)
if [ -z "$organizationOUs" ]; then
  echo "ERROR: No OUs found in the Hiperium Organization."
  exit 1
fi

### ITERATE OVER OUs TO ATTACH HIPERIUM SCP
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
    echo "Attaching Hiperium SCP to the ${ouName} OU..."
    aws organizations attach-policy \
      --policy-id "$scpId"          \
      --target-id "$ouId"
    echo "Done!"
    ;;
  *)
    echo "Your answer: No."
    ;;
  esac
done
