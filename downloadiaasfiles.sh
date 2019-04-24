#!/bin/bash
export local_prod_name="$1"
export local_prod_version="$2"

mkdir -p $WORKDIR
mkdir -p $DNLDDIR

echo "INFO - Authenticating the API Token"

curl --silent -i -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Token ${PIVNET_TOKEN}" \
            -X GET https://network.pivotal.io/api/v2/authentication > ${WORKDIR}/authenticate

if [ $(grep -c "HTTP/1.1 200 OK" ${WORKDIR}/authenticate) -ne 1 ]
then
	printf "Authentication failed, please check your API Token and try again.  Exiting...\n"
    cat ${WORKDIR}/authenticate
	exit 1
fi

echo "INFO - Setting the product slug for: " $local_prod_name
export prod_slug=""
export prod_slug=`curl --silent -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Token ${PIVNET_TOKEN}" \
            -X GET https://network.pivotal.io/api/v2/products |jq -r '.products[]|select (.name == env.local_prod_name).slug'`
if [ -z "$prod_slug" ]
then
    printf "Product slug not found.  Exiting...\n"
	exit 1
else
    echo "INFO - Got product slug: " $prod_slug
fi
export prod_id=`curl --silent -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Token ${PIVNET_TOKEN}" \
            -X GET https://network.pivotal.io/api/v2/products |jq -r '.products[]|select (.name == env.local_prod_name).id'`

echo "INFO - Setting the release id for: " $local_prod_name : $local_prod_version
export release_id=""
export release_id=`curl --silent -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Token ${PIVNET_TOKEN}" \
            -X GET https://network.pivotal.io/api/v2/products/${prod_slug}/releases|jq -r '.releases[]|select (.version == env.local_prod_version).id'`
if [ -z "$release_id" ]
then
    printf "Release ID not found.  Exiting...\n"
	exit 1
else
    echo "INFO - Got product Release ID: " $release_id
fi

echo "INFO - Getting the download links for: " $local_prod_name : $local_prod_version : $cloud
export download_links=""
export download_links=`curl --silent -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Token ${PIVNET_TOKEN}" \
        -X GET https://network.pivotal.io/api/v2/products/${prod_slug}/releases/${release_id} \
        |jq -r -S '.product_files[]|select (.file_type == "Software")|select (.name |test(env.cloud))._links.download.href'`
if [ -z "$download_links" ]
then
    printf "Download links not found.  Exiting...\n"
	exit 1
else
    echo "INFO - Got product Download Links: " $download_links
fi
export download_names=`curl --silent -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Token ${PIVNET_TOKEN}" \
        -X GET https://network.pivotal.io/api/v2/products/${prod_slug}/releases/${release_id} \
        |jq -r -S '.product_files[]|select (.file_type == "Software")|select (.name |test(env.cloud)).aws_object_key'`

echo "INFO - Got product Download Names: " $download_names

arrlinks=($download_links)
arrnames=($download_names)

echo "INFO - Accepting the agreement"

export eula_accepted=""
export eula_accepted=`curl --silent -H "Accept: application/json" -H "Content-Type: application/json" -H "Content-Length: 0" -H "Authorization: Token ${PIVNET_TOKEN}" \
	-X POST https://network.pivotal.io/api/v2/products/${prod_slug}/releases/${release_id}/eula_acceptance | jq -r .accepted_at`
if [ -z "$eula_accepted" ]
then
    printf "Error accepting EULA.  Exiting...\n"
        exit 1
else
    echo "INFO - EULA accepted: " $eula_accepted
fi

count=0
while [ "x${arrlinks[count]}" != "x" ]
do
	count=$(( $count + 1 ))
done

echo "INFO - Downloading the requested files"
c=0
while [[ $c -lt $count ]]
do
	download_url=${arrlinks[$c]}
	file=${arrnames[$c]}
#	echo $file
	target_file=`basename $file`
	echo "INFO - Downloading $target_file from $download_url"
	wget -q -nv --output-document="${DNLDDIR}/${target_file}" --post-data="" --header="Authorization: Token ${PIVNET_TOKEN}" ${download_url} --no-check-certificate
	let c=c+1
done
