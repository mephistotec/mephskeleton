#!/usr/bin/env bash
# Assume the deployment role on the target AWS account
echo "Current user info"
env | grep AWS
echo "Asuming temp role"
temp_role=$(aws sts assume-role \
                    --role-arn "arn:aws:iam::495248209902:role/KRAVD-Api-Access" \
                    --role-session-name "cicd-sysops")

echo "Setting variables $temp_role"

export AWS_ACCESS_KEY_ID=$(echo $temp_role | jq .Credentials.AccessKeyId | xargs)
export AWS_SECRET_ACCESS_KEY=$(echo $temp_role | jq .Credentials.SecretAccessKey | xargs)
export AWS_SESSION_TOKEN=$(echo $temp_role | jq .Credentials.SessionToken | xargs)

echo "Deploying $1...."

./kravd client \
        --method post \
        --url https://kravd.$2.k8s.mango/v1/resourceDeployments \
        --body $1
