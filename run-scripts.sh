#!/bin/bash

WORKING_DIR=$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
export WORKING_DIR

function setEnvironmentVariables() {
  echo ""
  read -r -p 'Please, enter the <AWS profile> to deploy the API on AWS: [profile default] ' aws_profile
  if [ -z "$aws_profile" ]; then
    AWS_PROFILE='default'
    export AWS_PROFILE
  else
    AWS_PROFILE=$aws_profile
    export AWS_PROFILE
  fi
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
    sh "$WORKING_DIR"/scp/create-scp.sh
    scpMenu
    ;;
  2)
    sh "$WORKING_DIR"/scp/update-scp.sh
    scpMenu
    ;;
  3)
    sh "$WORKING_DIR"/scp/delete-scp.sh
    scpMenu
    ;;
  4)
    sh "$WORKING_DIR"/scp/enable-hiperium-scp.sh
    scpMenu
    ;;
  5)
    sh "$WORKING_DIR"/scp/attach-scp-to-ou.sh
    scpMenu
    ;;
  6)
    sh "$WORKING_DIR"/scp/detach-scp-from-ou.sh
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
    echo -e 'Wrong option.'
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
    sh "$WORKING_DIR"/identity-center/store/create-group.sh
    identityMenu
    ;;
  2)
    sh "$WORKING_DIR"/identity-center/store/delete-group.sh
    identityMenu
    ;;
  3)
    sh "$WORKING_DIR"/identity-center/store/create-user.sh
    identityMenu
    ;;
  4)
    sh "$WORKING_DIR"/identity-center/store/delete-user.sh
    identityMenu
    ;;
  5)
    sh "$WORKING_DIR"/identity-center/store/create-group-membership.sh
    identityMenu
    ;;
  6)
    sh "$WORKING_DIR"/identity-center/store/delete-group-membership.sh
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
    echo -e 'Wrong option.'
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
    sh "$WORKING_DIR"/identity-center/permissions/create-permission-set.sh
    multiAccountMenu
    ;;
  2)
    sh "$WORKING_DIR"/identity-center/permissions/update-permission-set.sh
    multiAccountMenu
    ;;
  3)
    sh "$WORKING_DIR"/identity-center/permissions/delete-permission-set.sh
    multiAccountMenu
    ;;
  4)
    sh "$WORKING_DIR"/identity-center/permissions/put-inline-policy-to-permission-set.sh
    multiAccountMenu
    ;;
  5)
    sh "$WORKING_DIR"/identity-center/permissions/create-permission-set-assignments.sh
    multiAccountMenu
    ;;
  6)
    sh "$WORKING_DIR"/identity-center/permissions/delete-permission-set-assignments.sh
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
    echo -e 'Wrong option.'
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
  e) Environment variables.
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
    if [ -z "$AWS_PROFILE" ]; then
      setEnvironmentVariables
    fi
    sh "$WORKING_DIR"/scp/enable-hiperium-scp.sh
    sh "$WORKING_DIR"/scp/create-scp.sh
    sh "$WORKING_DIR"/scp/attach-scp-to-ou.sh
    sh "$WORKING_DIR"/identity-center/store/create-group.sh
    sh "$WORKING_DIR"/identity-center/store/create-user.sh
    sh "$WORKING_DIR"/identity-center/store/create-group-membership.sh
    sh "$WORKING_DIR"/identity-center/permissions/create-permission-set.sh
    sh "$WORKING_DIR"/identity-center/permissions/put-inline-policy-to-permission-set.sh
    sh "$WORKING_DIR"/identity-center/permissions/create-permission-set-assignments.sh
    menu
    ;;
  [Dd])
    clear
    if [ -z "$AWS_PROFILE" ]; then
      setEnvironmentVariables
    fi
    sh "$WORKING_DIR"/identity-center/store/delete-memberships-and-users.sh
    sh "$WORKING_DIR"/identity-center/permissions/delete-permission-set-assignments.sh
    sh "$WORKING_DIR"/identity-center/store/delete-group.sh
    sh "$WORKING_DIR"/identity-center/permissions/delete-permission-set.sh
    sh "$WORKING_DIR"/scp/detach-scp-from-ou.sh
    sh "$WORKING_DIR"/scp/delete-scp.sh
    sh "$WORKING_DIR"/scp/disable-hiperium-scp.sh
    menu
    ;;
  [Ee])
    clear
    if [ "$AWS_PROFILE" ]; then
      echo "AWS profile is already assigned: $AWS_PROFILE"
      read -r -p 'Do you want to change it? [y/N] ' change
      if [ "$change" = 'y' ] || [ "$change" = 'Y' ]; then
        setEnvironmentVariables
      fi
    fi
    menu
    ;;
  [Qq])
    clear
    exit 0
    ;;
  *)
    echo -e 'Wrong option.'
    clear
    menu
    ;;
  esac
}

clear
menu
