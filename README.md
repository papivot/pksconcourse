# Concourse Docker image/scripts and Pipeline for PKS/Harbor

How to deploy and run the pipeline - 

## **Option 1. (no changes to the scripts/task or the Dockerfile)**

**Preperation:** Create an S3 bucket (e.g. *mys3bucket-pks*) in the same region where you want to deploy the platform. Make sure the necessary access are provided. 

Create/upload a file called *terraform.tfvars.orig* in the bucket. The contents of a sample file is in this repository. Note that the *ops_manager_ami* value has to in the *format ami-xxxxxxxxxxxxx*. This value is replaced dynamically with the correct ami-id for the region specified. 

(TODO: Make this file more generic and update variables dynamically) 

**Step 1.** Copy the *sample_pipeline.yml* to an environment where the Concourse fly CLI is setup. 

**Step 2.** Modfiy the *sample_pipeline.yml* as per your requirements. Do not modify any references to this git resource type
```
type: git
  source:
    uri: https://github.com/papivot/pksconcourse.git
    branch: master
```

Also, do not modify any references to the image_resource type:
```
      image_resource:
        type: docker-image
        source:
          repository: whoami6443/pivdocker-auto
          tag: 'latest-final'
```

**Step 3.** Create an environment variable file in the same directory as the sample_pipeline.yml file was downloaded. 


Sample environment variable file (e.g. *envvariable.yml*) content - 

```
---
AWS_ACCESS_KEY_ID: AAAAAAAAAAAAAAA
AWS_SECRET_ACCESS_KEY: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
AWS_DEFAULT_REGION: us-east-2
AWS_S3_BUCKET: mys3bucket-pks
#
PRODUCT_OM: Pivotal Cloud Foundry Operations Manager
PRODUCT_OM_VERSION: 2.5.1
PRODUCT_ERT: Pivotal Application Service (formerly Elastic Runtime)
PRODUCT_ERT_VERSION: 2.5.1
PRODUCT_PKS: Pivotal Container Service (PKS)
PRODUCT_SLUG: pivotal-container-service
PRODUCT_PKS_VERSION: 1.4.0
STEMCELL: Stemcells for PCF (Ubuntu Xenial)
STEMCELL_VERSION: 250.25
# DO NOT modify the next line
cloud: AWS
#
PIVNET_TOKEN: XXXXXXXXXXXXXXXXXXXX
WORKDIR: /tmp/pivnet
DNLDDIR: /tmp/pivnet-out
EMAIL: myname@email.com
PASSWORD: Passw0rd
USERID: myname
```

**Step 4.** fly -t ci login -c *http://IP_OF_CONCOURSE:PORT*

**Step 5.** fly -t ci sp -p *my-pks-pipeline* -c *sample_pipeline.yml* -l *envvariable.yml*

**Step 6.** Unpause *my-pks-pipeline* pipeline. 
