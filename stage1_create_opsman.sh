#!/bin/bash

~/workspace/downloadiaasfiles.sh "$PRODUCT_OM" "$PRODUCT_OM_VERSION"
~/workspace/downloadiaasfiles.sh "$PRODUCT_ERT" "$PRODUCT_ERT_VERSION"

cd $DNLDDIR
unzip terraforming*.zip
cd pivotal-cf-terraforming-*/terraforming-pks
aws s3 cp s3://$AWS_S3_BUCKET/terraform.tfvars.$CLOUD terraform.tfvars

if [ "${CLOUD}" == "AWS" ]
then
    region=`awk '/region/ {print $3}' terraform.tfvars |sed 's/"//g'`
    if [ -z $region ] 
    then 
        echo "ERROR: Region missing in Terraform.tfvars file. Exit"
        exit 1
    fi

    original_ami=`awk '/ops_manager_ami/ {print $3}' terraform.tfvars |sed 's/"//g'`
    new_ami=`grep -w $region $DNLDDIR/ops-manager-aws-*.yml|awk '{print $2}'`
    if [ -z $new_ami ] 
    then 
        echo "ERROR: AMI entry not found for $region in ops-manager-aws-*.yml file. Exit"
        exit 1
    fi 
    sed -i "s/${original_ami}/${new_ami}/" terraform.tfvars
elif [ "${CLOUD}" == "GCP" ]
then
    
    original_image=`grep -w opsman_image_url terraform.tfvars|cut -d= -f2|sed 's/"//g'`
    new_image=`grep -w us: $DNLDDIR/ops-manager-gcp-*.yml |awk '{print $2}'`
    if [ -z $new_image ]
    then
        echo "ERROR: IMAGE entry not found for US in ops-manager-gcp-*.yml file. Exit"
        exit 1
    fi
    sed -i "s|${original_image}|https:\/\/storage.googleapis.com\/${new_image}|g" terraform.tfvars
fi

terraform init
terraform plan -out=plan
terraform apply plan
if [ $? -ne 0 ]
then
    echo "Error!!"
    exit 1
fi

# Opsman takes some time to start. Sleep
echo "INFO - On Some IaaS, Opsman take a while to start. Sleeping for 5mins..."
sleep 5m
terraform output ops_manager_public_ip

aws s3 cp terraform.tfstate s3://$AWS_S3_BUCKET/terraform.tfstate
aws s3 cp terraform.tfvars s3://$AWS_S3_BUCKET/terraform.tfvars.orig
