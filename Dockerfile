# To minimize the fetching of various layers this image and tag should
# be used as the base of the bhsm container in boulder/docker-compose.yml
FROM letsencrypt/boulder-tools:2016-07-08

# Boulder exposes its web application at port TCP 4000
EXPOSE 4000 4002 4003 8053 8055

ENV GO15VENDOREXPERIMENT 1
ENV PATH /go/bin:/usr/local/go/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin/
ENV GOPATH /go

RUN adduser --disabled-password --gecos "" --home /go/src/github.com/letsencrypt/boulder -q buser
RUN chown -R buser /go/

WORKDIR /go/src/github.com/letsencrypt/boulder

# Copy in the Boulder sources
COPY . .
RUN mkdir bin
RUN GOBIN=/usr/local/bin go install ./cmd/rabbitmq-setup

RUN GOBIN=/go/src/github.com/letsencrypt/boulder/bin go install  ./...
## Use specific settings for development
## Should update common secction.
COPY ./local/boulder-config.local.json /go/src/github.com/letsencrypt/boulder/test/boulder-config.json
COPY ./local/rate-limit-policies.yml /go/src/github.com/letsencrypt/boulder/test/rate-limit-policies.yml
COPY ./local/cakey.pem /go/src/github.com/letsencrypt/boulder/test/test-ca.key
COPY ./local/cacert.pem /go/src/github.com/letsencrypt/boulder/test/test-ca.pem

RUN chown -R buser /go/

ENTRYPOINT [ "./test/entrypoint.sh" ]
CMD [ "./start.py" ]
