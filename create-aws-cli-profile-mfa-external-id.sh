#This will create the source profile and the role profile
# Enter the name of the profile with the credentials (source profile)
# Enter the name of the profile that is configured to use the role (role profile)
# external id is optional but should be used with external accounts

echo "Enter source profile name"
read SOURCE_PROFILE

echo "Enter Key ID:"
read AWS_ACCESS_KEY_ID

echo "Enter secret access key:"
read AWS_SECRET_ACCESS_KEY

echo "Enter region (e.g. us-east-1)"
read REGION

echo "Enter role profile"
read PROFILE

echo "Enter role arn"
read ROLE_ARN

echo "Enter mfa arn"
read MFA_SERIAL

echo "Enter external id"
read EXTERNAL_ID

echo "Enter output format (e.g. json or text)"
read OUTPUT

aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID" --profile "$SOURCE_PROFILE"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY" --profile "$SOURCE_PROFILE"
aws configure set region "$REGION" --profile "$SOURCE_PROFILE"
aws configure set output "$OUTPUT" --profile "$SOURCE_PROFILE"

aws configure set role_arn "$ROLE_ARN" --profile "$PROFILE"
aws configure set mfa_serial "$MFA_SERIAL" --profile "$PROFILE"
if [ "$EXTERNAL_ID" != "" ]; then 
  aws configure set external_id "$EXTERNAL_ID" --profile "$PROFILE"
fi
aws configure set region "$REGION" --profile "$PROFILE"
aws configure set output "$OUTPUT" --profile "$PROFILE"
aws configure set source_profile "$SOURCE_PROFILE" --profile "$PROFILE"

#test your profile
aws sts get-caller-identity --profile "$PROFILE"

