echo "Enter profile name"
read profile

echo "Enter Key ID:"
read aws_access_key_id

echo "Enter secret access key:"
read aws_secret_access_key

echo "Enter region (e.g. us-east-1)"
read region

echo "Enter output format (e.g. json or text)"
read output

aws configure set aws_access_key_id $aws_access_key_id --profile $profile
aws configure set aws_secret_access_key $aws_secret_access_key --profile $profile
aws configure set region $region --profile $profile
aws configure set output $output --profile $profile

#test your profile
aws sts get-caller-identity --profile $profile
