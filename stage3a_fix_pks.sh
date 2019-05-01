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

if [ "${CLOUD}" == "AWS" ]
then
    export vpc_id=`terraform output vpc_id`
    export pks_vm_id=`aws ec2 describe-instances --filters "Name=tag:instance_group,Values=pivotal-container-service"|jq -r '.Reservations[].Instances[].InstanceId'`
    export pks_sg_id=`aws ec2 describe-security-groups --filters "Name=vpc-id,Values=${vpc_id}"|jq -r '.SecurityGroups[]|select (.GroupName == "pks_api_lb_security_group").GroupId'`
    export def_sg_id=`aws ec2 describe-security-groups --filters "Name=vpc-id,Values=${vpc_id}"|jq -r '.SecurityGroups[]|select (.GroupName == "vms_security_group").GroupId'`

    echo "INFO - Fixing Security Group for PKS API Instance ID $pks_vm_id"
    aws ec2 modify-instance-attribute --instance-id $pks_vm_id --groups $pks_sg_id $def_sg_id

    for tgt_grp in $(terraform output pks_api_target_groups)
    do
        tgt=`echo $tgt_grp|tr -d ,`
        arn=`aws elbv2 describe-target-groups --name $tgt |jq -r '.TargetGroups[].TargetGroupArn'`
        echo "INFO - Addoing PKS API Instance ID $pks_vm_id to TG $arn"
        aws elbv2 register-targets --target-group-arn $arn --targets Id=$pks_vm_id
    done
fi
