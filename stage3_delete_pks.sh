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

#export PRODUCT_SLUG="pivotal-container-service"
export FILE_VER=`om -t $OM_IP -u ${EMAIL} -p ${PASSWORD} -k deployed-products -f json |jq -r '.[]|select (.name == env.PRODUCT_SLUG).version'`

echo "INFO - Will delete the following from OM: " ${PRODUCT_SLUG} ${FILE_VER}

om -t $OM_IP -u ${EMAIL} -p ${PASSWORD} -k unstage-product --product-name ${PRODUCT_SLUG}
#om -t $OM_IP -u ${EMAIL} -p ${PASSWORD} -k apply-changes --skip-unchanged-products
om -t $OM_IP -u ${EMAIL} -p ${PASSWORD} -k apply-changes
om -t $OM_IP -u ${EMAIL} -p ${PASSWORD} -k delete-product --product-name ${PRODUCT_SLUG} --product-version ${FILE_VER}
