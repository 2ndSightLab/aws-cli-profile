#!/bin/bash

# List available profiles and ask for profile to use
echo "Available AWS CLI profiles:"
aws configure list-profiles
echo
echo "Enter profile name to use or type 'new' to create a new profile:"
while true; do
    read -p "Profile: " PROFILE_INPUT
    if [[ "$PROFILE_INPUT" == "new" ]]; then
        echo "Select profile type:"
        echo "1. Use AWS Credentials Only"
        echo "2. Assume a Role with MFA"
        while true; do
            read -p "Enter choice (1 or 2): " CHOICE
            if [[ "$CHOICE" == "1" ]]; then
                source ./create-aws-cli-profile-simple.sh
                break
            elif [[ "$CHOICE" == "2" ]]; then
                source ./create-aws-cli-profile-mfa-external-id.sh
                break
            else
                echo "Invalid choice. Please enter 1 or 2."
            fi
        done
        break
    elif aws configure list-profiles | grep -q "^$PROFILE_INPUT$"; then
        PROFILE="$PROFILE_INPUT"
        break
    else
        echo "Profile not found. Please enter a valid profile name or 'new'."
    fi
done

# Run aws sts get-caller-identity with the profile to verify it works
echo "Verifying profile works:"
aws sts get-caller-identity --profile "$PROFILE"

# Prompt for service name
while true; do
    read -p "Enter service name or 'list' to view all services: " SERVICE_INPUT
    if [[ "$SERVICE_INPUT" == "list" ]]; then
        echo "AWS service names:"
        aws help | grep "AVAILABLE SERVI" -A1900 | grep o | cut -d " " -f9- | grep -v 'aws help topics'
    elif [[ -n "$SERVICE_INPUT" ]]; then
        SERVICE_NAME="$SERVICE_INPUT"
        break
    else
        echo "Please enter a service name."
    fi
done

# List the AWS Managed policies names for that service by listing the services that have the service name in the policy document. Ignore case.
echo "AWS Managed policies for $SERVICE_NAME:"
aws iam list-policies --scope AWS --profile "$PROFILE" --query 'Policies[].PolicyName' --output text | tr '\t' '\n' | grep -i "$SERVICE_NAME"

# Prompt for the policy name to be copied
while true; do
    read -p "Enter policy name to copy: " POLICY_TO_COPY
    if aws iam get-policy --policy-arn "arn:aws:iam::aws:policy/$POLICY_TO_COPY" --profile "$PROFILE" >/dev/null 2>&1; then
        break
    else
        echo "Policy not found. Please enter a valid policy name."
    fi
done

# Ask about permission limitations
read -p "Limit permissions to specific account? (y/n): " LIMIT_ACCOUNT
if [[ "$LIMIT_ACCOUNT" =~ ^[Yy]$ ]]; then
    echo "AWS Accounts in organization:"
    aws organizations list-accounts --profile "$PROFILE" --query 'Accounts[].[Id,Name]' --output table
    while true; do
        read -p "Enter Account ID: " ACCOUNT_ID
        if [[ "$ACCOUNT_ID" =~ ^[0-9]{12}$ ]]; then
            read -p "Do you want to create the role in that account? (y/n): " CREATE_IN_ACCOUNT
            if [[ "$CREATE_IN_ACCOUNT" =~ ^[Yy]$ ]]; then
                read -p "What role to assume: " ASSUME_ROLE_NAME
                ASSUME_ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/$ASSUME_ROLE_NAME"
                # Set profile to use assumed role for role creation commands
                CREATION_PROFILE="temp-assumed-role"
                aws configure set role_arn "$ASSUME_ROLE_ARN" --profile "$CREATION_PROFILE"
                aws configure set source_profile "$PROFILE" --profile "$CREATION_PROFILE"
            else
                CREATION_PROFILE="$PROFILE"
            fi
            ROLE_NAME="${POLICY_TO_COPY}_${ACCOUNT_ID}_MFA"
            break
        else
            echo "Invalid Account ID format."
        fi
    done
else
    read -p "Limit permissions to specific OU? (y/n): " LIMIT_OU
    if [[ "$LIMIT_OU" =~ ^[Yy]$ ]]; then
        echo "Organizational Units:"
        aws organizations list-organizational-units-for-parent --parent-id $(aws organizations list-roots --profile "$PROFILE" --query 'Roots[0].Id' --output text) --profile "$PROFILE" --query 'OrganizationalUnits[].[Id,Name]' --output table
        while true; do
            read -p "Enter OU ID: " OU_ID
            if [[ "$OU_ID" =~ ^ou-[a-z0-9]+-[a-z0-9]+$ ]]; then
                ROLE_NAME="${POLICY_TO_COPY}_${OU_ID}_MFA"
                CREATION_PROFILE="$PROFILE"
                break
            else
                echo "Invalid OU ID format."
            fi
        done
    else
        read -p "Limit permissions to this organization? (y/n): " LIMIT_ORG
        if [[ "$LIMIT_ORG" =~ ^[Yy]$ ]]; then
            ORG_ID=$(aws organizations describe-organization --profile "$PROFILE" --query 'Organization.Id' --output text)
            ROLE_NAME="${POLICY_TO_COPY}_${ORG_ID}_MFA"
        else
            ROLE_NAME="${POLICY_TO_COPY}_MFA"
        fi
        CREATION_PROFILE="$PROFILE"
    fi
fi

# List user ARNs and select one
echo "User ARNs:"
aws iam list-users --profile "$PROFILE" --query 'Users[].[UserName,Arn]' --output table
while true; do
    read -p "Enter username for role assumption: " USERNAME
    USER_ARN=$(aws iam get-user --user-name "$USERNAME" --profile "$PROFILE" --query 'User.Arn' --output text 2>/dev/null)
    if [[ -n "$USER_ARN" ]]; then
        break
    else
        echo "User not found."
    fi
done

# Create trust policy with MFA requirement
TRUST_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "$USER_ARN"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "Bool": {
          "aws:MultiFactorAuthPresent": "true"
        }
      }
    }
  ]
}
EOF
)

# Create the role
if aws iam get-role --role-name "$ROLE_NAME" --profile "$CREATION_PROFILE" >/dev/null 2>&1; then
    while true; do
        read -p "Role $ROLE_NAME already exists. Do you want to overwrite it? (y/n): " OVERWRITE_ROLE
        if [[ "$OVERWRITE_ROLE" =~ ^[Yy]$ ]]; then
            # Detach all policies from role before deleting
            aws iam list-attached-role-policies --role-name "$ROLE_NAME" --profile "$CREATION_PROFILE" --query 'AttachedPolicies[].PolicyArn' --output text | tr '\t' '\n' | while read POLICY_ARN; do
                aws iam detach-role-policy --role-name "$ROLE_NAME" --policy-arn "$POLICY_ARN" --profile "$CREATION_PROFILE" >/dev/null 2>&1
            done
            aws iam delete-role --role-name "$ROLE_NAME" --profile "$CREATION_PROFILE" >/dev/null 2>&1
            break
        elif [[ "$OVERWRITE_ROLE" =~ ^[Nn]$ ]]; then
            echo "Exiting without creating role."
            exit 1
        else
            echo "Please enter y or n."
        fi
    done
fi
aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document "$TRUST_POLICY" --profile "$CREATION_PROFILE"
ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --profile "$CREATION_PROFILE" --query 'Role.Arn' --output text)

# Get and modify the policy from the original policy
POLICY_ARN="arn:aws:iam::aws:policy/$POLICY_TO_COPY"
POLICY_NAME=$(basename "$POLICY_ARN")
NEW_POLICY_NAME="${ROLE_NAME}_${POLICY_NAME}"

# Get policy document
POLICY_VERSION=$(aws iam get-policy --policy-arn "$POLICY_ARN" --profile "$PROFILE" --query 'Policy.DefaultVersionId' --output text)
POLICY_DOCUMENT=$(aws iam get-policy-version --policy-arn "$POLICY_ARN" --version-id "$POLICY_VERSION" --profile "$PROFILE" --query 'PolicyVersion.Document')

# Modify policy to limit actions based on scope
if [[ -n "$ACCOUNT_ID" ]]; then
    # For account limitation, add condition instead of modifying resources
    MODIFIED_POLICY=$(echo "$POLICY_DOCUMENT" | jq --arg account "$ACCOUNT_ID" '
        .Statement[] |= if .Condition then .Condition.StringEquals."aws:RequestedRegion" = "*" else .Condition = {"StringEquals": {"aws:RequestedRegion": "*"}} end')
elif [[ -n "$OU_ID" ]]; then
    # Limit to specific OU - add condition
    MODIFIED_POLICY=$(echo "$POLICY_DOCUMENT" | jq --arg ou "$OU_ID" '
        .Statement[] |= if .Condition then .Condition.StringEquals."aws:PrincipalOrgPaths" = ["*/ou-root/" + $ou + "/*"] else .Condition = {"StringEquals": {"aws:PrincipalOrgPaths": ["*/ou-root/" + $ou + "/*"]}} end')
elif [[ -n "$ORG_ID" ]]; then
    # Limit to organization
    MODIFIED_POLICY=$(echo "$POLICY_DOCUMENT" | jq --arg org "$ORG_ID" '
        .Statement[] |= if .Condition then .Condition.StringEquals."aws:PrincipalOrgID" = $org else .Condition = {"StringEquals": {"aws:PrincipalOrgID": $org}} end')
else
    MODIFIED_POLICY="$POLICY_DOCUMENT"
fi

# Create new policy and attach to role
ACCOUNT_ID_CURRENT=$(aws sts get-caller-identity --profile "$CREATION_PROFILE" --query Account --output text)
if aws iam get-policy --policy-arn "arn:aws:iam::$ACCOUNT_ID_CURRENT:policy/$NEW_POLICY_NAME" --profile "$CREATION_PROFILE" >/dev/null 2>&1; then
    while true; do
        read -p "Policy $NEW_POLICY_NAME already exists. Do you want to overwrite it? (y/n): " OVERWRITE_POLICY
        if [[ "$OVERWRITE_POLICY" =~ ^[Yy]$ ]]; then
            # Delete all non-default versions first
            aws iam list-policy-versions --policy-arn "arn:aws:iam::$ACCOUNT_ID_CURRENT:policy/$NEW_POLICY_NAME" --profile "$CREATION_PROFILE" --query 'Versions[?!IsDefaultVersion].VersionId' --output text | tr '\t' '\n' | while read VERSION; do
                aws iam delete-policy-version --policy-arn "arn:aws:iam::$ACCOUNT_ID_CURRENT:policy/$NEW_POLICY_NAME" --version-id "$VERSION" --profile "$CREATION_PROFILE" >/dev/null 2>&1
            done
            aws iam delete-policy --policy-arn "arn:aws:iam::$ACCOUNT_ID_CURRENT:policy/$NEW_POLICY_NAME" --profile "$CREATION_PROFILE" >/dev/null 2>&1
            break
        elif [[ "$OVERWRITE_POLICY" =~ ^[Nn]$ ]]; then
            echo "Using existing policy."
            NEW_POLICY_ARN="arn:aws:iam::$ACCOUNT_ID_CURRENT:policy/$NEW_POLICY_NAME"
            aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn "$NEW_POLICY_ARN" --profile "$CREATION_PROFILE"
            exit 0
        else
            echo "Please enter y or n."
        fi
    done
fi
NEW_POLICY_ARN=$(aws iam create-policy --policy-name "$NEW_POLICY_NAME" --policy-document "$MODIFIED_POLICY" --profile "$CREATION_PROFILE" --query 'Policy.Arn' --output text)
if [[ -n "$NEW_POLICY_ARN" && "$NEW_POLICY_ARN" != "None" ]]; then
    aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn "$NEW_POLICY_ARN" --profile "$CREATION_PROFILE"
    echo "Policy attached successfully."
else
    echo "Error: Failed to create policy. Policy not attached to role."
fi

echo "New role created: $ROLE_ARN"
echo "Trust Policy:"
echo "$TRUST_POLICY"
echo "Policy:"
echo "$MODIFIED_POLICY"
