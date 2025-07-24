#!/bin/bash

# Configurable role name to assume in each member account
ROLE_NAME="CrossAccountAuditRole"
OUTPUT_DIR="AllAccountsIAMPolicies"
mkdir -p "$OUTPUT_DIR"

# Get all active account IDs in the organization
ACCOUNT_IDS=$(aws organizations list-accounts \
    --query 'Accounts[?Status==`ACTIVE`].Id' \
    --output text)

# Loop through each account
for ACCOUNT_ID in $ACCOUNT_IDS; do
  echo "Processing Account: $ACCOUNT_ID"

  # Assume the role in the member account
  CREDS=$(aws sts assume-role \
    --role-arn arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME} \
    --role-session-name IAMPolicyAuditSession \
    --query 'Credentials' --output json)

  if [ -z "$CREDS" ]; then
    echo "Failed to assume role in account: $ACCOUNT_ID"
    continue
  fi

  # Extract temporary credentials
  export AWS_ACCESS_KEY_ID=$(echo "$CREDS" | jq -r '.AccessKeyId')
  export AWS_SECRET_ACCESS_KEY=$(echo "$CREDS" | jq -r '.SecretAccessKey')
  export AWS_SESSION_TOKEN=$(echo "$CREDS" | jq -r '.SessionToken')

  # Get users
  USER_LIST=$(aws iam list-users --query "Users[*].UserName" --output text)
  mkdir -p "$OUTPUT_DIR/$ACCOUNT_ID"

  for user in $USER_LIST; do
    echo "Fetching policies for user: $user"

    aws iam list-attached-user-policies --user-name "$user" --output json > attached_policies.json
    aws iam list-user-policies --user-name "$user" --output json > inline_policies.json

    # Combine both policy sets into one file
    jq -s '.[0] + {InlinePolicies: .[1]}' attached_policies.json inline_policies.json > "$OUTPUT_DIR/$ACCOUNT_ID/${user}.json"
    echo "Saved to $OUTPUT_DIR/$ACCOUNT_ID/${user}.json"
  done

  # Clean up
  rm -f attached_policies.json inline_policies.json
done

# Clear session credentials
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

echo "Completed IAM user policy collection for all accounts."
