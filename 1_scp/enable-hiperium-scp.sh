#!/bin/bash
set -e

echo ""
echo "ENABLING ORGANIZATIONS SCP..."
aws organizations enable-policy-type  \
  --root-id "$ORG_ROOT_ID"            \
  --policy-type SERVICE_CONTROL_POLICY > /dev/null
echo "DONE!"
