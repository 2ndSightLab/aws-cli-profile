#This will create the source profile and the role profile
# Enter the name of the profile with the credentials (source profile)
# Enter the name of the profile that is configured to use the role (role profile)
# external id is optional but should be used with external accounts

echo "Enter source profile name"
read source_profile

echo "Enter Key ID:"
read aws_access_key_id

echo "Enter secret access key:"
read aws_secret_access_key

echo "Enter region (e.g. us-east-1)"
read region

echo "Enter role profile"
read role_profile

echo "Enter role arn"
read role_arn

echo "Enter mfa arn"
read mfa_serial

echo "Enter external id"
read external_id

echo "Enter output format (e.g. json or text)"
read output

aws configure set aws_access_key_id $aws_access_key_id --profile $source_profile
aws configure set aws_secret_access_key $aws_secret_access_key --profile $source_profile
aws configure set region $region --profile $source_profile
aws configure set output $output --profile $source_profile

aws configure set role_arn $role_arn --profile $role_profile
aws configure set mfa_serial $mfa_serial --profile $role_profile
if [ "$external_id" != "" ]; then 
  aws configure set external_id $external_id --profile $role_profile
fi
aws configure set region $region --profile $role_profile
aws configure set output $output --profile $role_profile
aws configure set source_profile $source_profile --profile $role_profile

#test your profile
aws sts get-caller-identity --profile $role_profile
