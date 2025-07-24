# 🛠️ Project Deep Dive: Cross-Account IAM User Audit

This document explains the complete process of auditing IAM users across multiple AWS accounts using a centralized audit account and CloudFormation StackSets.

---

## 🧾 Table of Contents

1. [Purpose](#purpose)
2. [Architecture](#architecture)
3. [CloudFormation Role Setup](#cloudformation-role-setup)
4. [Trust Policy](#trust-policy)
5. [Permissions Policy](#permissions-policy)
6. [Bash Script Functionality](#bash-script-functionality)
7. [Running the Script](#running-the-script)
8. [Output Samples](#output-samples)
9. [Security Recommendations](#security-recommendations)
10. [Limitations](#limitations)

---

## 🎯 Purpose

To automatically gather IAM users, their attached and inline policies, across all accounts in an AWS Organization, and generate both JSON and CSV reports from a single point.

---

## 🏗️ Architecture

- The **audit script** runs in the **management (or delegated audit) account**.
- A **CloudFormation StackSet** deploys an IAM role (`CrossAccountAuditRole`) to each member account.
- The script **assumes the role** in each account and fetches IAM data via AWS CLI calls.

---

## 📦 CloudFormation Role Setup

Create a StackSet using the template `cloudformation/cross-account-audit-role.yaml`.

- Deploy it to **Organizational Units (OUs)** or **specific accounts**.
- Set external ID or org conditions for security.
- IAM Role created: `CrossAccountAuditRole`

---

## 🔐 Trust Policy

Used by member accounts to allow the central account to assume the role:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::<ORG_ACCOUNT_ID>:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
Note: In principal, arn of the role attached to the user you're logged in to run the script and after should mentioned the assumed role arn for all the aws accounts. 

📜 Permissions Policy
Attached to CrossAccountAuditRole:

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:ListUsers",
        "iam:GetUser",
        "iam:ListAttachedUserPolicies",
        "iam:ListUserPolicies",
        "iam:GetUserPolicy",
        "iam:GetPolicy",
        "iam:GetPolicyVersion",
        "iam:ListPolicyVersions",
        "organizations:ListAccounts",
        "sts:AssumeRole"
      ],
      "Resource": "*"
    }
  ]
}

⚙️ Bash Script Functionality
Script path: scripts/iam-user-audit.sh

Lists all AWS accounts via organizations:ListAccounts
Assumes the role in each account using aws sts assume-role
Loops through users using aws iam list-users
Fetches:
  Attached policies (list-attached-user-policies)
  Inline policies (list-user-policies + get-user-policy)
Stores:
  One JSON per account → output/<ACCOUNT_ID>.json
  A consolidated CSV file → all_accounts_iam_users.csv

🚀 Running the Script
1. Configure your AWS CLI profile in the Org/Audit account:
aws configure --profile org-admin

2. Execute the script:
./scripts/iam-user-audit.sh

3. Outputs:
output/*.json
all_accounts_iam_users.csv

📄 Output Samples
JSON (one per account):
[
  {
    "UserName": "john.doe",
    "AttachedPolicies": ["ReadOnlyAccess"],
    "InlinePolicies": ["CustomAuditPolicy"]
  }
]

CSV (combined):
AccountID	UserName	AttachedPolicies	InlinePolicies
123456789012	john.doe	ReadOnlyAccess	CustomAuditPolicy

🔐 Security Recommendations
Always use least privilege when assigning permissions.
Limit AssumeRole access to only the Org root or specific IAM roles.
Store output files securely and rotate credentials periodically.

⚠️ Limitations
Does not handle IAM groups or roles.
Requires AWS CLI v2 and jq.
Assumes all accounts successfully deployed the StackSet.
Federated users (SSO) are not fetched in this version.
