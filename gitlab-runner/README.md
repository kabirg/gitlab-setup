# Deploy the GitLab Runner


## Run the GitLab Runner Container
On the other EC2 instance, run the following command to deploy a runner container:

    docker run -d --name gitlab-runner --restart always \
     -v /srv/gitlab-runner/config:/etc/gitlab-runner \
     -v /var/run/docker.sock:/var/run/docker.sock \
     gitlab/gitlab-runner:latest


## Store the SSL Certificate on the Runner:
This is an important step before registering our runner with the GitLab master.

All servers have a "Trusted Store" database of trusted CA's that they use to verify SSL certs. However, When you generate a self-signed cert, the custom CA is not stored in that database. This means that the runner will still not trust your SSL cert.

To get around this, we need to store that certificate on the runner also. This way, it can verify the GitLab cert against the version it has locally.

We want to store the cert in a directory in the container that maps to a volume on the host, that way both the runner's host and runner-container can establish trust.

**Steps:**
  - Open a bash session in the runner container:
      > docker exec -it gitlab-runner /bin/bash
  - Store the cert here (make the directory if it doesn't exist):
      > /etc/gitlab-runner/certs/


## Register the Runner with GitLab:
Get the registration token:
  - In GitLab > Pick a project you want to create a runner for (create a project if none exists yet).
  - In that project > Settings > CI/CD > Select 'Expand' in the Runners section.
  - In the *'Set up a specific Runner manually'* section, copy the URL and registration token.
  - Register the runner using the command below (paste in your own domain, cert-name, and registration token).

  **Note** - this command is being run on the EC2 instance itself (not the runner-container, exit out of it to come back to the instance).

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

You can verify the registration in the GitLab console. The newly registered runner should appear in an **"Activated Runners"** section of the project's CI/CD settings (under **Runners**).
