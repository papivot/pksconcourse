#!/bin/bash

~/workspace/downloadiaasfiles.sh "$PRODUCT_OM" "$PRODUCT_OM_VERSION"
~/workspace/downloadiaasfiles.sh "$PRODUCT_ERT" "$PRODUCT_ERT_VERSION"

cd $DNLDDIR
unzip terraforming*.zip
cd pivotal-cf-terraforming-*/terraforming-pks
aws s3 cp s3://$AWS_S3_BUCKET/terraform.tfvars.orig terraform.tfvars
aws s3 cp s3://$AWS_S3_BUCKET/terraform.tfstate terraform.tfstate

terraform init
terraform refresh
OM_IP=`terraform output ops_manager_public_ip`
PKS_EP=`terraform output pks_api_endpoint`
TOKEN=`om -t $OM_IP -u $EMAIL -p $PASSWORD -k credentials --product-name ${PRODUCT_SLUG} -c .properties.pks_uaa_management_admin_client -t json | jq -r .secret`

uaac target https://$PKS_EP:8443  --skip-ssl-validation
uaac token client get admin  -s $TOKEN
uaac user add $USERID --emails $EMAIL -p $PASSWORD
uaac member add pks.clusters.admin $USERID
pks login -a ${PKS_EP} -u ${USERID} -p ${PASSWORD} -k
pks create-cluster $CLUSTER_NAME --external-hostname $CLUSTER_NAME.$DNS  --plan small
status=`pks cluster $CLUSTER_NAME --json|jq -r .last_action_state`
while [ "$status" = "in progress" ] 
do 
  echo "Cluster build in progress... sleeping 2m" 
  sleep 2m
  status=`pks cluster $CLUSTER_NAME --json|jq -r .last_action_state`
done
