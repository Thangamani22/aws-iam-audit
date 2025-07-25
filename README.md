# aws-iam-audit
# 🔍 Cross-Account IAM User Audit on AWS

This project enables centralized auditing of IAM users and their policies across multiple AWS accounts under a single AWS Organization. It uses a combination of **AWS CloudFormation StackSet** and a **Bash script** to deploy and query a cross-account IAM role (`CrossAccountAuditRole`).

---

## 🚀 Features

- Deploys an IAM role across all member accounts via StackSet
- Uses `sts:AssumeRole` to access IAM data from each account
- Collects:
  - IAM user list
  - Attached managed policies
  - Inline policy names
- Exports results:
  - **Per-account JSON** files
  - **Consolidated CSV** report

---

## ⚙️ Prerequisites

- AWS Organization must be enabled
- CloudFormation StackSet permission to deploy IAM role (`CrossAccountAuditRole`)
- Audit role trust policy must allow `AssumeRole` from org account
- Permissions required for IAM and Organizations APIs

---

## 🔧 Setup Instructions

### 1. Deploy IAM Role via CloudFormation

Use `cloudformation/cross-account-audit-role.yaml` to deploy `CrossAccountAuditRole` across accounts via StackSet.

Update the trust policy with your Organization ID or specific account ARNs.

### 2. Run the Audit Script

```bash
cd scripts
chmod +x iam-user-audit.sh
./iam-user-audit.sh
Script will:

List all AWS accounts in your Organization

Assume the CrossAccountAuditRole into each account

Fetch IAM user data and policies

Write output to output/ACCOUNT_ID.json and all_accounts_iam_users.csv

📄 Output
output/111111111111.json: IAM user details for that account

all_accounts_iam_users.csv: Combined CSV with:

Account ID

Username

Attached Policies

Inline Policies

🔐 Security Best Practices
Apply least privilege principle to CrossAccountAuditRole

Limit trust to your org or audit accounts only

Avoid wildcard trust policies in production

🧠 Learn More
Full documentation and step-by-step guide:
📄 Documentation.md

✍️ Author
Thangamani R — Cloud Engineer | AWS | Automation | Security Audit
Feel free to connect on LinkedIn
