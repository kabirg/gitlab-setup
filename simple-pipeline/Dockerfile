# We are using this base image b/c: CFN_NAG depends on ruby2.5, and alpine is small.
# https://github.com/stelligent/cfn_nag
FROM ruby:2.5-alpine3.10

LABEL maintainer="Kabir Gupta <kabirgupta3@gmail.com>"

# Leaving this blank to grab latest.
ARG version=''

RUN gem install cfn-nag --version "$version"

# Replacing Stelligent's default command with SH instead.
# This will drop us into an interactive shell by default (if we use -it when running the container)
# ENTRYPOINT ["cfn_nag"]
# CMD ["--help"]
CMD sh
