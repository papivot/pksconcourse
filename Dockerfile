FROM ubuntu:18.04

# Install.
RUN  \
    apt-get update -y && apt-get install build-essential software-properties-common -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y zlibc zlib1g-dev ruby ruby-dev openssl libxslt1-dev libxml2-dev libssl-dev libreadline7 libreadline-dev libyaml-dev libsqlite3-dev sqlite3 curl git unzip vim wget jq groff awscli rubygems && \
    export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" && \
    echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    apt-get update -y && apt-get install google-cloud-sdk -y && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /root/workspace

COPY download* /root/workspace/

#COPY stage* /root/workspace/

RUN /usr/bin/wget https://releases.hashicorp.com/terraform/0.11.13/terraform_0.11.13_linux_amd64.zip && \
    unzip terraform*.zip && \
    chmod +x terraform && \
    mv terraform /usr/local/bin/terraform && \
    rm terraform*.zip

RUN wget https://github.com/cloudfoundry/bosh-cli/releases/download/v5.5.0/bosh-cli-5.5.0-linux-amd64 && \
    chmod +x bosh-cli-5.5.0-linux-amd64 && \
    mv bosh-cli-5.5.0-linux-amd64 /usr/local/bin/bosh

RUN wget https://github.com/pivotal-cf/om/releases/download/0.56.0/om-linux && \
    mv om-linux /usr/local/bin/om && \
    chmod +x /usr/local/bin/om

RUN gem install cf-uaac

COPY texplate /usr/local/bin/texplate


# Set environment variables.
ENV HOME /root

# Define working directory.
WORKDIR /root/workspace

# Define default command.
CMD ["bash"]
