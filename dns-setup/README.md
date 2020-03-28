# DNS Setup
---

## Purchase a domain from a registrar.

Route53 is now a registrar but there are cheap options like Namecheap or GoDaddy.

We'll use example.com as an example domain.


## Setup DNS (using Route53)

  1. In Route53, create a create a public hosted zone.
    > Public Hosted Zone: handles/routes internet traffic and is a container for your DNS records.
  2. Upon creation, you get an NS and SOA record.
    > NS record: lists your 4 authoritative nameservers.
    > SOA record: contains information about your domain.
  3. Create the A record in the hosted zone and point it to the public IP of your Gitlab server.
  4. Validate DNS is setup for your domain:
    > nslookup example.com <nameserver>
    > For the nslookup command, you can use the domain name of any of your nameservers (found in the NS record)

This allows us to resolve the hostname to an IP.


## Point the Registrar to the Authoritative Nameservers

The process varies depending on which registrar you went with. But to use GoDaddy as an example:
  1. In the GoDaddy homepage navigate to 'Domains' > 'All Domains' > Select your domain.
  2. Click on 'Manage DNS'
  3. Add all 4 AWS nameservers (and their IP's, you can ping the nameservers to get their IP's)

  > It can take anywhere from a few minutes, to up to 48 hours for the DNS changes to take effect.

Verify that the configuration is in effect by pinging your domain.


## Update the Gitlab Domain

Back in the docker-compose file in the Gitlab server:
  - Update the hostname and external_url parameters to swap the IP for the new domain
  - Apply the changes:
    > docker-compose down
    > docker-compose up -d

You should now be able to access Gitlab via the domain-name URL. Now to setup SSL.
