#!/bin/bash
set -e

echo ""
echo "CREATING HIPERIUM SCP..."
aws organizations create-policy                                                       \
  --name "hiperium-scp-policy"                                                        \
  --description "Deny list of services for the Hiperium Organization."                \
  --content file://"$WORKING_DIR"/templates/iam/policies/hiperium-scp-policy.json     \
  --type SERVICE_CONTROL_POLICY > /dev/null
echo "DONE!"
