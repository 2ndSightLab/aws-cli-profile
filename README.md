# aws-cli-profile
Create an AWS CLI profile programmatically.
Includes remote role assumption with MFA and external ID.

__1. configure a profile programmatcially__

create-aws-cli-profile-simple.sh

__2. create a source profile and a profile that assumes a role with mfa__

create-aws-cli-profile-mfa-external-id.sh

__3. create a copy of an AWS managed role limited to a specific account, organization, or organizational unit and require MFA__

Steps to create script:

* Create a script named create-service-role.sh
* List available profiles and ask for the profile to use to deploy the role or ask the user if they want to create a new one.
* If the user enters a profile store it in a variable named PROFILE.
* If the user wants to create a new profile ask if they want to assume a role with MFA or use a profile with user credentials.
* If the user wants to set up an AWS CLI profile with user credentials source this script to create a profile: create-aws-cli-profile-simple.sh
* If the user nees to create a new profile source this script create-aws-cli-profile-simple.sh
* After any of the above the profile name should be stored in the variable PROFILE.
* Prompt for a service name or enter list to view all services.
* If the entry is list then list all AWS service names as they appear in AWS roles.
* Use a while loop to ask the user for service names until a service name has been entered.
* List the AWS Managed roles for that service.
* Prompt for the role name to be copied.
* Ask if permissions should be limited to actions to in a specific account
* If yes, limit to account, List aws accounts and names in the organization
* If yes, limit to account, Enter the account in which the role can be used and store in ACCOUNT_ID
* Set the value of role name to the name of the selected role with "_$ACCOUNT_ID_MFA" at the end
* Else, Ask if permissions should be limited to actions to in a specific  OU
* If yes, limit to OU, List aws OUs and names in the organization
* If yes, limit to OU, Enter the OU Id in which the role can be used and store in OU_ID
* Set the value of role name to the name of the selected role with "_$OU_ID_MFA" at the end
* Else, Ask if permissions should be limited to actions to this organization
* If yes, limit to organization, set ORG_ID to the organization ID
* List the user ARNs
* Select the user ARN that is allowed to assume the role
* Create a new role with the specified ROLE_NAME with a trust policy that requires MFA.
* Copy the policy of the selected role to copy and modify it to limit the actions to the specified account, OU, or organization.
* Get the value of the new role arn in variable ROLE_ARN.
* Print 'New role created: $ROLE_ARN'
* Print 'Trust Policy:' followed by trust policy on the next line.
* Print 'Policy:' followed by the current policy document of the policy assigned to the role.

** Add the same policy to the role as the AWS Managed Role
* Create the AWS CLI Profile to assume the new role with the specified source profile
