#!/bin/bash

~/workspace/downloadiaasfiles.sh "$PRODUCT_OM" "$PRODUCT_OM_VERSION"
~/workspace/downloadiaasfiles.sh "$PRODUCT_ERT" "$PRODUCT_ERT_VERSION"

cd $DNLDDIR
unzip terraforming*.zip
cd pivotal-cf-terraforming-*/terraforming-pks
aws s3 cp s3://$AWS_S3_BUCKET/terraform.tfvars.orig terraform.tfvars
aws s3 cp s3://$AWS_S3_BUCKET/terraform.tfstate terraform.tfstate

PROJECT_DIR=`dirname $PWD`

terraform init
terraform refresh
OM_IP=`terraform output ops_manager_public_ip`
om -t $OM_IP -k configure-authentication -u ${EMAIL} -p ${PASSWORD} -dp ${PASSWORD}
om -t $OM_IP -u ${EMAIL} -p ${PASSWORD} -k configure-director --config <(texplate execute $PROJECT_DIR/ci/assets/template/director-config.yml -f  <(jq -e --raw-output '.modules[0].outputs | map_values(.value)' terraform.tfstate) -o yaml)
om -t $OM_IP -u ${EMAIL} -p ${PASSWORD} -k apply-changes
