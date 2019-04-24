#!/bin/bash

~/workspace/downloadiaasfiles.sh "$PRODUCT_OM" "$PRODUCT_OM_VERSION"
~/workspace/downloadiaasfiles.sh "$PRODUCT_ERT" "$PRODUCT_ERT_VERSION"
~/workspace/downloadfiles.sh "$PRODUCT_PKS" "$PRODUCT_PKS_VERSION"
~/workspace/downloadiaasfiles.sh "$STEMCELL" "$STEMCELL_VERSION"

cd $DNLDDIR
unzip terraforming*.zip
cd pivotal-cf-terraforming-*/terraforming-pks
aws s3 cp s3://$AWS_S3_BUCKET/terraform.tfvars.orig terraform.tfvars
aws s3 cp s3://$AWS_S3_BUCKET/terraform.tfstate terraform.tfstate

PROJECT_DIR=`dirname $PWD`

terraform init
terraform refresh
OM_IP=`terraform output ops_manager_public_ip`

PRODUCTFILE=`ls -1 $DNLDDIR/*.pivotal`
STEMCELLFILE=`ls -1 $DNLDDIR/*stemcell*`
PRODUCT_SLUG=`cat $WORKDIR/prod_slug.txt`
FILE_VER=`cat $WORKDIR/file_version`

om -t $OM_IP -u ${EMAIL} -p ${PASSWORD} -k upload-product -p ${PRODUCTFILE}
om -t $OM_IP -u ${EMAIL} -p ${PASSWORD} -k upload-STEMCELL -s ${STEMCELLFILE}
om -t $OM_IP -u ${EMAIL} -p ${PASSWORD} -k stage-product --product-name ${PRODUCT_SLUG} --product-version ${FILE_VER}

texplate execute $PROJECT_DIR/ci/assets/template/pks-config.yml -f <(jq -e --raw-output '.modules[0].outputs | map_values(.value)' terraform.tfstate) -o yaml > pcs.yml
#sed -i '1iproduct-name: pivotal-container-service' pcs.yml
#sed -i '/pivotal-container-service.pks_tls/,+3d' pcs.yml
om -t $OM_IP -u ${EMAIL} -p ${PASSWORD} -k configure-product --config pcs.yml
om -t $OM_IP -u ${EMAIL} -p ${PASSWORD} -k apply-changes
