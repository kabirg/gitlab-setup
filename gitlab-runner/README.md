# Deploy the GitLab Runner
---


## Run the GitLab Runner Container

docker run -d --name gitlab-runner --restart always \
  -v /srv/gitlab-runner/config:/etc/gitlab-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  gitlab/gitlab-runner:latest


## Store the SSL Certificate on the Runner:

This is an important step before registering our runner with the GitLab master.

  > All servers have a "Trusted Store" database of trusted CA's that they use to verify SSL certs. However, When you generate a self-signed cert, the custom CA is not stored in that database. This means that the runner will still not trust your SSL cert.
  >
  > To get around this, we need to store the certificate on the runner also. This way, it can verify the GitLab cert against the version it has locally.
  >
  > We want to store the cert in a directory in the container that maps to a volume on the host, that way both the host and container can establish trust.

  1. docker exec -it gitlab-runner /bin/bash
  2. Store the certs here:
    > /etc/gitlab-runner/certs/example.com.crt


## Register the Runner with the Master:

Get the registration token:
  1. In GitLab > Pick a project you want to create a runner for
    > Create a project if none exists yet.
  2. In that project > Settings > CI/CD > Select 'Expand' in the Runners section.
  3. Grab the URL and Token for the next command)
  4. In the 'Set up a specific Runner manually' section, copy the registration token.
  5. Register the runner:
    > Use your own domain, cert, and registration token in the command below.

docker run --rm -v /srv/gitlab-runner/config:/etc/gitlab-runner gitlab/gitlab-runner register \
  --non-interactive \
  --executor "docker" \
  --docker-image alpine:latest \
  --url "https://example.com/" \
  --registration-token "xxxxxxxxxxxxxxxxxx" \
  --description "docker-runner" \
  --tag-list "docker,aws" \
  --run-untagged="true" \
  --locked="false" \
  --access-level="not_protected" \
  --docker-volumes /var/run/docker.sock:/var/run/docker.sock \
  --tls-ca-file "/etc/gitlab-runner/certs/example.com.crt"

You can verify this in the GitLab console. The newly registered runner should appear in the "Activated Runners" section of the project's CI/CD settings.
