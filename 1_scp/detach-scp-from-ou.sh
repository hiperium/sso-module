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
  exit 0
fi
echo "- Hiperium SCP ID: $scpId"

echo ""
echo "DETACHING HIPERIUM SCP FROM OUs..."

### FIND OUs
organizationOUs=$(aws organizations list-organizational-units-for-parent \
  --parent-id "$ORG_ROOT_ID" \
  --output json)
if [ -z "$organizationOUs" ]; then
  echo "ERROR: No OUs found in the Hiperium Organization."
  exit 0
fi

### DETACH SCP FROM OUs
for ou in $(echo "$organizationOUs" | jq -r '.OrganizationalUnits[] | @base64'); do
  _jq() {
    echo "${ou}" | base64 --decode | jq -r "${1}"
  }
  ouId=$(_jq '.Id')
  ouName=$(_jq '.Name')
  echo ""
  echo "- OU ID: $ouName"

  ouPolicies=$(aws organizations list-policies-for-target \
    --target-id "$ouId" \
    --filter SERVICE_CONTROL_POLICY)
  numberOfPolicies=$(echo "$ouPolicies" | jq '.Policies | length')
  echo "- Number of SCPs attached: $numberOfPolicies"

  echo "$ouPolicies" | jq -r '.Policies[] | @base64' | while read -r policy; do
    _jq() {
      echo "${policy}" | base64 --decode | jq -r "${1}"
    }
    policyId=$(_jq '.Id')
    policyName=$(_jq '.Name')
    if [ "$policyName" == "hiperium-scp-policy" ]; then
      echo "- Hiperium SCP found. Detaching it..."
      aws organizations detach-policy \
        --policy-id "$policyId"       \
        --target-id "$ouId"
      echo "Done!"
      break
    fi
  done
done
