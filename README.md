# aws-cli-profile

__Summary__

Scripts to create AWS CLI profiles, roles, and role policies

__Global Context__

* All variable names should be upper case with a _ between each word.
* Each value should be checked for proper type or a valid value from the approriate list of values based on the options provided by the script or valid values defined in the AWS documentation.
* Each prompt should exist in a while loop that asks the user to enter a value until a valid value has been entered.

__Scripts__

__1. configure a profile programmatcially__

create-aws-cli-profile-simple.sh

__2. create a source profile and a profile that assumes a role with mfa__

create-aws-cli-profile-mfa-external-id.sh

__3. create a copy of an AWS managed role limited to a specific account, organization, or organizational unit and require MFA__

Steps to create script:

* Use the global context at the top of the readme
* Create a script named create-service-role.sh
* List available profiles and ask for the profile to use to deploy the role or ask the user if they want to create a new one.
* If the user enters a profile store it in a variable named PROFILE.
* If the user wants to create a new profile, profile two options and ask the user to select one: 1. Use AWS Credentials Only 2. Assume a Role with MFA. Check for a valid entry in a loop and ask the user to enter a value again until we get a valid entry.
* If the user wants to set up an AWS CLI profile with user credentials source this script to create a profile: create-aws-cli-profile-simple.sh
* If the user nees to create a new profile source this script create-aws-cli-profile-simple.sh
* After any of the above the profile name should be stored in the variable PROFILE.
* Run aws sts get-caller-identity with the profile to verify it works
* Prompt for a service name or enter list to view all services.
* If the entry is list then use this command to list aws services: aws help | grep "AVAILABLE SERVI" -A1900 | grep o | cut -d " " -f9- | grep -v 'aws help topics'
* Use a while loop to ask the user for service names until a service name has been entered.
* List the AWS Managed policies names for that service by listing the services that have the service name in the policy document. Ignore case.
* Prompt for the policy name to be copied.
* Ask if permissions should be limited to actions to in a specific account
* If yes, limit to account, List aws accounts and names in the organization
* If yes, limit to account, Enter the account in which the role can be used and store in ACCOUNT_ID
* Ask if the user wants to create the role in that account
* If yes, ask what role to assume then assume that role for the commands that create the role and the profile
* Set the value of role name to the name of the selected policy with "_$ACCOUNT_ID_MFA" at the end
* Else, Ask if permissions should be limited to actions to in a specific  OU
* If yes, limit to OU, List aws OUs and names in the organization
* If yes, limit to OU, Enter the OU Id in which the role can be used and store in OU_ID
* Set the value of role name to the name of the selected policy with "_$OU_ID_MFA" at the end
* Else, Ask if permissions should be limited to actions to this organization
* If yes, limit to organization, set ORG_ID to the organization ID
* List the user ARNs
* Select the user ARN that is allowed to assume the role
* Create a new role with the specified ROLE_NAME with a trust policy that requires MFA.
* Copy the policy of the selected policy and modify it to limit the actions to the specified account, OU, or organization.
* Get the value of the new role arn in variable ROLE_ARN.
* Print 'New role created: $ROLE_ARN'
* Print 'Trust Policy:' followed by trust policy on the next line.
* Print 'Policy:' followed by the current policy document of the policy assigned to the role.
* Attach the policy to the new role
