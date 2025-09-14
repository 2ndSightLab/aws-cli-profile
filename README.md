# aws-cli-profile
Create an AWS CLI profile programmatically.
Includes remote role assumption with MFA and external ID.

__1. configure a profile programmatcially__

create-aws-cli-profile-simple.sh

__2. create a source profile and a profile that assumes a role with mfa__

create-aws-cli-profile-mfa-external-id.sh

__3. create a profile to use service actions in a specifc account__

Steps to create script:

* Create a script named create-service-profile.sh
* List available profiles
* Ask for default profile
* List service names
* Enter service name for which to create a profile
* Enter read or write
* Create a role that can be assumed with MFA by the user associated with the default profile
* Add the required permissions for the service (read, write or all)
* Create the AWS CLI Profile to assume the new role with the specified source profile
