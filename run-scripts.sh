#!/bin/bash
set -e

WORKING_DIR=$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
export WORKING_DIR

function setEnvironmentVariables() {
  echo ""
  read -r -p 'Enter the <AWS profile> to manage your Organization: [default] ' aws_profile
  if [ -z "$aws_profile" ]; then
    aws_profile='default'
  fi
  sh "$WORKING_DIR"/helper/verify-aws-profile-existence.sh "$aws_profile"
  AWS_PROFILE=$aws_profile
  export AWS_PROFILE

  echo ""
  echo "GETTING INFORMATION FROM AWS. PLEASE WAIT..."

  ### GET ORGANIZATION ID
  rootId=$(aws organizations list-roots           \
    --query "Roots[?contains(Name, 'Root')].[Id]" \
    --output text)
  if [ -z "$rootId" ]; then
    echo "ERROR: Organization <Root> NOT found in your AWS account..."
    exit 1
  fi
  echo "- Organization ID: $rootId"
  export ORG_ROOT_ID=$rootId

  ### GET IDENTITY STORE ID
  storeId=$(sh "$WORKING_DIR"/common/get-identity-store-id.sh)
  if [ -z "$storeId" ]; then
    echo "ERROR: Hiperium Identity Store NOT found in IAM Identity Center..."
    exit 1
  fi
  echo "- Identity Store ID: $storeId"
  export IDENTITY_STORE_ID=$storeId

  ### GET INSTANCE ARN
  instanceArn=$(sh "$WORKING_DIR"/common/get-sso-instance-arn.sh)
  if [ -z "$instanceArn" ]; then
    echo "ERROR: No IAM Identity Center instance found in your AWS account..."
    exit 0
  fi
  echo "- Instance ARN: $instanceArn"
  export SSO_INSTANCE_ARN=$instanceArn
}

function scpMenu() {
  echo "
  *************************************
  ****** SERVICE CONTROL POLICY *******
  *************************************
  1)  Create SCP.
  2)  Update SCP.
  3)  Delete SCP.
  4)  Enable Organizations SCPs.
  5)  Attach SCP to OUs.
  6)  Detach SCP from OUs.
  -------------------------------------
  r) Return.
  q) Quit.
  "
  read -r -p 'Choose an option: ' option
  case $option in
  1)
    sh "$WORKING_DIR"/1_scp/create-scp.sh
    scpMenu
    ;;
  2)
    sh "$WORKING_DIR"/1_scp/update-scp.sh
    scpMenu
    ;;
  3)
    sh "$WORKING_DIR"/1_scp/delete-scp.sh
    scpMenu
    ;;
  4)
    sh "$WORKING_DIR"/1_scp/enable-hiperium-scp.sh
    scpMenu
    ;;
  5)
    sh "$WORKING_DIR"/1_scp/attach-scp-to-ou.sh
    scpMenu
    ;;
  6)
    sh "$WORKING_DIR"/1_scp/detach-scp-from-ou.sh
    scpMenu
    ;;
  [Rr])
    clear
    menu
    ;;
  [Qq])
    clear
    exit 0
    ;;
  *)
    echo 'Wrong option.'
    clear
    scpMenu
    ;;
  esac
}

function identityMenu() {
  echo "
  *************************************
  ******** IAM IDENTITY STORE *********
  *************************************
  1) Create Group.
  2) Delete Group.
  3) Create User.
  4) Delete User.
  5) Create Group Membership.
  6) Delete Group Membership.
  -------------------------------------
  r) Return.
  q) Quit.
  "
  read -r -p 'Choose an option: ' option
  case $option in
  1)
    sh "$WORKING_DIR"/2_identity-store/create-group.sh
    identityMenu
    ;;
  2)
    sh "$WORKING_DIR"/2_identity-store/delete-group.sh
    identityMenu
    ;;
  3)
    sh "$WORKING_DIR"/2_identity-store/create-user.sh
    identityMenu
    ;;
  4)
    sh "$WORKING_DIR"/2_identity-store/delete-user.sh
    identityMenu
    ;;
  5)
    sh "$WORKING_DIR"/2_identity-store/create-group-membership.sh
    identityMenu
    ;;
  6)
    sh "$WORKING_DIR"/2_identity-store/delete-group-membership.sh
    identityMenu
    ;;
  [Rr])
    clear
    menu
    ;;
  [Qq])
    clear
    exit 0
    ;;
  *)
    echo 'Wrong option.'
    clear
    identityMenu
    ;;
  esac
}

function multiAccountMenu() {
  echo "
  *************************************
  ***** MULTI-ACCOUNT PERMISSIONS *****
  *************************************
  1) Create Permission Set.
  2) Update Permission Set.
  3) Delete Permission Set.
  4) Put Inline Policy.
  5) Create Account Assignments.
  6) Delete Account Assignments.
  -------------------------------------
  r) Return.
  q) Quit.
  "
  read -r -p 'Choose an option: ' option
  case $option in
  1)
    sh "$WORKING_DIR"/3_identity-permissions/create-permission-set.sh
    multiAccountMenu
    ;;
  2)
    sh "$WORKING_DIR"/3_identity-permissions/update-permission-set.sh
    multiAccountMenu
    ;;
  3)
    sh "$WORKING_DIR"/3_identity-permissions/delete-permission-set.sh
    multiAccountMenu
    ;;
  4)
    sh "$WORKING_DIR"/3_identity-permissions/put-inline-policy-to-permission-set.sh
    multiAccountMenu
    ;;
  5)
    sh "$WORKING_DIR"/3_identity-permissions/create-permission-set-assignments.sh
    multiAccountMenu
    ;;
  6)
    sh "$WORKING_DIR"/3_identity-permissions/delete-permission-set-assignments.sh
    multiAccountMenu
    ;;
  [Rr])
    clear
    menu
    ;;
  [Qq])
    clear
    exit 0
    ;;
  *)
    echo 'Wrong option.'
    clear
    multiAccountMenu
    ;;
  esac
}

function menu() {
  echo "
  *************************************
  ************* MAIN MENU *************
  *************************************
  1) Service Control Policies (SCPs).
  2) IAM Identity Store.
  3) Multi-Account Permissions.
  -------------------------------------
  c) Create ALL.
  d) Delete All.
  q) Quit.
  "
  read -r -p 'Choose an option: ' option
  case $option in
  1)
    clear
    scpMenu
    ;;
  2)
    clear
    identityMenu
    ;;
  3)
    clear
    multiAccountMenu
    ;;
  [Cc])
    clear
    sh "$WORKING_DIR"/1_scp/enable-hiperium-scp.sh
    sh "$WORKING_DIR"/1_scp/create-scp.sh
    sh "$WORKING_DIR"/1_scp/attach-scp-to-ou.sh
    sh "$WORKING_DIR"/2_identity-store/create-group.sh
    sh "$WORKING_DIR"/2_identity-store/create-user.sh
    sh "$WORKING_DIR"/2_identity-store/create-group-membership.sh
    sh "$WORKING_DIR"/3_identity-permissions/create-permission-set.sh
    sh "$WORKING_DIR"/3_identity-permissions/put-inline-policy-to-permission-set.sh
    sh "$WORKING_DIR"/3_identity-permissions/create-permission-set-assignments.sh
    clear
    echo ""
    echo "DONE!"
    menu
    ;;
  [Dd])
    clear
    sh "$WORKING_DIR"/2_identity-store/delete-memberships-and-users.sh
    sh "$WORKING_DIR"/3_identity-permissions/delete-permission-set-assignments.sh
    sh "$WORKING_DIR"/2_identity-store/delete-group.sh
    sh "$WORKING_DIR"/3_identity-permissions/delete-permission-set.sh
    sh "$WORKING_DIR"/1_scp/detach-scp-from-ou.sh
    sh "$WORKING_DIR"/1_scp/delete-scp.sh
    sh "$WORKING_DIR"/1_scp/disable-hiperium-scp.sh
    clear
    echo ""
    echo "DONE!"
    menu
    ;;
  [Qq])
    clear
    exit 0
    ;;
  *)
    echo 'Wrong option.'
    clear
    menu
    ;;
  esac
}

clear
setEnvironmentVariables
clear
menu
