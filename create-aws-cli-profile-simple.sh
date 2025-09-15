echo "Enter profile name"
read PROFILE

echo "Enter Key ID:"
read AWS_ACCESS_KEY_ID

echo "Enter secret access key:"
read AWS_SECRET_ACCESS_KEY

echo "Enter region (e.g. us-east-1)"
read REGION

echo "Enter output format (e.g. json or text)"
read OUTPUT

aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID --profile $PROFILE
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY --profile $PROFILE
aws configure set region $REGION --profile $PROFILE
aws configure set output $OUTPUT --profile $PROFILE

#test your profile
aws sts get-caller-identity --profile $PROFILE
