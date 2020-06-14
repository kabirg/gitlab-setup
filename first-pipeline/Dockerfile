FROM python:3.7-alpine3.11

ARG AWSCLI_VERSION=1.18.76

RUN apk -uv --no-cache add \
    groff \
    jq \
    less && \
    pip install --no-cache-dir awscli==$AWSCLI_VERSION

CMD sh
