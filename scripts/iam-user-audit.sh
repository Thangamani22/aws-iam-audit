#!/bin/bash

ROLE_NAME="CrossAccountAuditRole"
OUTPUT_DIR="AllAccountsIAMPolicies"
mkdir -p "$OUTPUT_DIR"

ACCOUNT_IDS=$(aws organizations list-accounts \
    --query 'Accounts[?Status==`ACTIVE`].Id' \
    --output text)

for ACCOUNT_ID in $ACCOUNT_IDS; do
  echo "Processing Account: $ACCOUNT_ID"

  CREDS=$(aws sts assume-role \
    --role-arn arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME} \
    --role-session-name IAMPolicyAuditSession \
    --query 'Credentials' --output json)

  if [ -z "$CREDS" ]; then
    echo "Failed to assume role in account: $ACCOUNT_ID"
    continue
  fi

  export AWS_ACCESS_KEY_ID=$(echo "$CREDS" | jq -r '.AccessKeyId')
  export AWS_SECRET_ACCESS_KEY=$(echo "$CREDS" | jq -r '.SecretAccessKey')
  export AWS_SESSION_TOKEN=$(echo "$CREDS" | jq -r '.SessionToken')

  USER_LIST=$(aws iam list-users --query "Users[*].UserName" --output text)
  mkdir -p "$OUTPUT_DIR/$ACCOUNT_ID"
  CSV_FILE="$OUTPUT_DIR/$ACCOUNT_ID.csv"
  echo "AccountID,UserName,AttachedPolicies,InlinePolicies" > "$CSV_FILE"

  for user in $USER_LIST; do
    echo "Fetching policies for user: $user"

    ATTACHED=$(aws iam list-attached-user-policies --user-name "$user" --output json)
    INLINE=$(aws iam list-user-policies --user-name "$user" --output json)

    # Save JSON
    echo "$ATTACHED" > attached_policies.json
    echo "$INLINE" > inline_policies.json
    jq -s '.[0] + {InlinePolicies: .[1]}' attached_policies.json inline_policies.json > "$OUTPUT_DIR/$ACCOUNT_ID/${user}.json"

    # Parse and write to CSV
    ATTACHED_NAMES=$(echo "$ATTACHED" | jq -r '.AttachedPolicies[].PolicyName' | paste -sd ";" -)
    INLINE_NAMES=$(echo "$INLINE" | jq -r '.PolicyNames[]' | paste -sd ";" -)
    echo "$ACCOUNT_ID,$user,\"$ATTACHED_NAMES\",\"$INLINE_NAMES\"" >> "$CSV_FILE"
  done

  rm -f attached_policies.json inline_policies.json
done

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

echo "Completed IAM user policy collection for all accounts (JSON + CSV)."
