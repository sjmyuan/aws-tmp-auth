#!/bin/bash -e

get_credential(){
  local default_user=$USER
  local username=""
  local userid=""
  local jwt_id_token=""
  echo -n "Username [$default_user]: "
  read username
  if [ -z $username ]; then
    userid=$default_user
  else
    userid=$username
  fi

  # password = the user's password
  if [ -n "$ZSH_VERSION" ]; then
    read -s "userpw?Password: "
  else
    read -s -p "Password: " userpw
  fi

  jwt_id_token=$(aws cognito-idp initiate-auth --auth-flow USER_PASSWORD_AUTH --auth-parameter "USERNAME=${userid},PASSWORD=${userpw}" --client-id $CLIENT_ID --query AuthenticationResult.IdToken --output text --region $AWS_REGION)
  unset userpw
  cognito_identity_id=$(aws cognito-identity get-id --identity-pool-id "$IDENTITY_POOL_ID" --logins {\"cognito-idp.$AWS_REGION.amazonaws.com/${USER_POOL_ID}\":\"${jwt_id_token}\"} --query IdentityId --output text --region $AWS_REGION)
  environments=$(aws cognito-identity get-credentials-for-identity --identity-id "$cognito_identity_id" --logins {\"cognito-idp.$AWS_REGION.amazonaws.com/${USER_POOL_ID}\":\"${jwt_id_token}\"} --region $AWS_REGION)
  export AWS_ACCESS_KEY_ID=$( echo $environments | jq -r '.Credentials.AccessKeyId' )
  export AWS_SECRET_ACCESS_KEY=$( echo $CREDS | jq -r '.Credentials.SecretKey' )
  export AWS_SECURITY_TOKEN=$( echo $CREDS | jq -r '.Credentials.SessionToken' )
  export AWS_SESSION_TOKEN=$AWS_SECURITY_TOKEN
  export AWS_EXPIRETIME=$( echo $CREDS | jq -r '.Credentials.Expiration' )
  echo -n "Success!"
}

export AWS_ACCESS_KEY_ID='WillNotUseButNeedExist'
export AWS_SECRET_ACCESS_KEY='WillNotUseButNeedExist'
export AWS_REGION=
export USER_POOL_ID=
export IDENTITY_POOL_ID=
export CLIENT_ID=

# 1. get the token from cognito user pool
# 2. get the id from cognito identity pool
# 3. get the temporary credential by id
# 4. set the environment
get_credential
