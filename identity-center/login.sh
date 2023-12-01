#!/bin/bash
set -e

echo ""
echo "Hiperium Project's SSO Login on AWS..."
echo ""
aws sso login --sso-session city-sso
echo ""
