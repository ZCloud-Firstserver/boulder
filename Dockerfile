FROM golang:1.5

MAINTAINER J.C. Jones "jjones@letsencrypt.org"
MAINTAINER William Budington "bill@eff.org"

# Install dependencies packages
RUN apt-get update && apt-get install -y \
    libltdl-dev \
	mariadb-client-core-10.0 \
    nodejs \
	rsyslog \
	--no-install-recommends \
  	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Boulder exposes its web application at port TCP 4000
EXPOSE 4000

# Install port forwarder
RUN go get github.com/jsha/listenbuddy
# get database migration tool
RUN go get bitbucket.org/liamstask/goose/cmd/goose
# install go lint
RUN go get -v github.com/golang/lint/golint

# Assume the configuration is in /etc/boulder
ENV BOULDER_CONFIG /go/src/github.com/letsencrypt/boulder/test/boulder-config.json
ENV GOPATH /go/src/github.com/letsencrypt/boulder/Godeps/_workspace:$GOPATH

WORKDIR /go/src/github.com/letsencrypt/boulder

# Copy in the Boulder sources
COPY . /go/src/github.com/letsencrypt/boulder

## Use specific settings for development
## Should update common secction.
COPY ./local/boulder-config.local.json /go/src/github.com/letsencrypt/boulder/test/boulder-config.json
COPY ./local/rate-limit-policies.yml /go/src/github.com/letsencrypt/boulder/test/rate-limit-policies.yml
COPY ./local/cakey.pem /go/src/github.com/letsencrypt/boulder/test/test-ca.key
COPY ./local/cacert.pem /go/src/github.com/letsencrypt/boulder/test/test-ca.pem

ENTRYPOINT [ "./test/entrypoint.sh" ]
CMD [ "./start.py" ]
