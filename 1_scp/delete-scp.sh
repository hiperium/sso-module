#!/bin/bash
set -e

echo ""
echo "GETTING INFORMATION FROM AWS. PLEASE WAIT..."

### GETTING HIPERIUM SCP ID
scpId=$(aws organizations list-policies --filter SERVICE_CONTROL_POLICY \
  --query "Policies[?contains(Name, 'hiperium-scp-policy') && contains(Type, 'SERVICE_CONTROL_POLICY')].[Id]" \
  --output text)
if [ -z "$scpId" ]; then
  echo "ERROR: Hiperium SCP NOT found..."
  exit 1
fi
echo "- Hiperium SCP ID: $scpId"

echo ""
echo "DELETING HIPERIUM SCP..."
aws organizations delete-policy   \
  --policy-id "$scpId"
echo "DONE!"



