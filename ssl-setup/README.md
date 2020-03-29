# SSL Setup

At a high-level, we need to:
  - Create a private key
  - Create a CSR (a request for a certificate)
  - Get the certificate (we will sign it ourselves with the private key - a *self-signed certificate*)


## Create the Private Key:
    openssl genrsa -out *example.com*.key 2048

Use your domain in place of *example.com*


## Create the CSR (Certificate Signing Request):
    openssl req -key example.com.key -new -out csr.csr

Again use your domain in place of *example.com*

  > This is the order request for the cert.
  >
  > You’ll be prompted to specify information like your email, org, and the Common Name.
  >
  > **Common Name**: the domain that you’re requesting the cert for.
  >
  > Once the CSR is created, you either send it to a CA (Certificate Authority) to sign, or you can sign it yourself (using your private key and the x509 command).
  >
  > We're going to do the latter and sign it ourselves...


## Self-Sign the Certificate:
    openssl x509 -signkey example.com.key -in csr.csr -req -days 365 -out example.com.crt

Again use your domain in place of *example.com*

  > The contents of this cert will be **base64 (PEM) encoded**, which is what we want (as opposed to binary (DER) encoding).
  >
  > It doesn't matter if the resulting file is a **.pem** or **.crt**, those are just file extensions. What matters is that the contents of the file are PEM encoded, which this command should do.
  >
  > You can verify this by **cat**'ing the file and making sure it is in human-readable format.


## Add the Key & Certificate to the "/etc/gitlab/ssl" Location:
SSH into the Gitlab instance...
  - Open a bash session in Gitlab container:
    sudo docker exec -it gitlab /bin/bash
  - Make the target location if it doesn't already exist:
      > mkdir -p /etc/gitlab/ssl
      >
      > chmod 755 /etc/gitlab/ssl
  - Copy/paste the key and cert into this directory.
  - Run ***sudo gitlab-ctl reconfigure***


## Update the NGINX Configuration
Back in the docker-compose file:
  - Update **external_url** to us *https* instead of *http*
  - Add the following code to the GITLAB_OMNIBUS_CONFIG (under the external_url):

        nginx['ssl_certificate'] = '/etc/gitlab/ssl/example.com.crt'
        nginx['ssl_certificate_key'] = '/etc/gitlab/ssl/example.com.key'
        
  - Apply the changes:

        docker-compose down
        docker-compose up -d

You should now be able to access your Gitlab instance via the HTTPS URL!
