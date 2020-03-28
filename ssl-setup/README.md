# SSL Setup
---

## Create the Private Key:

openssl genrsa -out example.com.key 2048


## Create the CSR (Certificate Signing Request):

openssl req -key example.com.key -new -out csr.csr
  > This is the order request for the cert.
  > You’ll be prompted to specify information like your email, org, and the Common Name.
  > Common Name: the domain that you’re requesting the cert for.
  > Once the CSR is created, you either send it to a CA (Certificate Authority) to sign, or you can sign it yourself (using your private key and the x509 command).
  > We're going to do the latter and sign it ourselves...


## Self-Sign the Certificate:

openssl x509 -signkey example.com.key -in csr.csr -req -days 365 -out example.com.crt
  > The contents of this cert will be base64 (PEM) encoded, which is what we want (as opposed to binary (DER) encoding).
  > It doesn't matter if the resulting file is a .pem or .crt, those are just file extensions. What matters is that the contents of the file are PEM encoded, which this command should do.
  > You can verify this by cat'ing the file and making sure it is in human-readable format.


## Add the Key & Certificate to the "/etc/gitlab/ssl" Location:

SSH into the Gitlab instance...
    1. Open a bash session in Gitlab container:
      > sudo docker exec -it gitlab /bin/bash
    2. Copy/paste the key and cert into the proper location:
      > mkdir -p /etc/gitlab/ssl
      > chmod 755 /etc/gitlab/ssl
    3. sudo gitlab-ctl reconfigure


## Update the NGINX Configuration

Back in the docker-compose file in the Gitlab server:
  - Update the external_url parameter value from 'http' to 'https'
  - Add the following code to the GITLAB_OMNIBUS_CONFIG (under the external_url):
    > nginx['ssl_certificate'] = '/etc/gitlab/ssl/example.com.crt'
    > nginx['ssl_certificate_key'] = '/etc/gitlab/ssl/example.com.key'
  - - Apply the changes:
    > docker-compose down
    > docker-compose up -d

You should now be able to access your Gitlab instance via the HTTPS URL.
