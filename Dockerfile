FROM thinca/vim:latest

ENV PACKAGES="\
    bash \
    make \
"
RUN apk --update add $PACKAGES && \
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

RUN mkdir plugin tests
ADD plugin plugin
ADD run-test.sh .
ADD tests tests

ENTRYPOINT []
