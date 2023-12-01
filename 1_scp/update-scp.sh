#!/bin/bash
set -e

echo ""
echo "GETTING INFORMATION FROM AWS. PLEASE WAIT..."

### GETTING HIPERIUM SCP ID
scpId=$(aws organizations list-policies --filter SERVICE_CONTROL_POLICY \
  --query "Policies[?contains(Name, 'hiperium-scp-policy') && contains(Type, 'SERVICE_CONTROL_POLICY')].[Id]" \
  --output text)
if [ -z "$scpId" ]; then
  echo "ERROR: Hiperium SCP NOT found on AWS..."
  exit 0
fi
echo "- Hiperium SCP ID: $scpId"

echo ""
echo "UPDATING HIPERIUM SCP..."
aws organizations update-policy     \
  --policy-id "$scpId"              \
  --content file://"$WORKING_DIR"/templates/iam/policies/hiperium-scp-policy.json
echo "DONE!"
