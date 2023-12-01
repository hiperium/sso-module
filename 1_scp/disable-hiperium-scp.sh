#!/bin/bash
set -e

echo ""
echo "DISABLING ORGANIZATIONS SCP..."
aws organizations disable-policy-type                 \
  --root-id "$ORG_ROOT_ID"                            \
  --policy-type SERVICE_CONTROL_POLICY > /dev/null
echo "DONE!"
