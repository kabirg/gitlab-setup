# DNS Setup


## Purchase a domain from a registrar.
Route53 is now a registrar but there are also cheap options like GoDaddy.

We'll use *example.com* as an example domain.


## Setup DNS (using Route53)
  - In Route53, create a create a public hosted zone.
      > **Public Hosted Zone**: handles/routes internet traffic and is a container for your DNS records.
  - Upon creation, you get an NS and SOA record.
      > **NS record**: lists your 4 authoritative nameservers.
      >
      > **SOA record**: contains information about your domain.
  - Create an A record in the hosted zone and point it to the public IP of your Gitlab server.
  - Validate DNS is setup for your domain:
      > ***nslookup example.com NAMESERVER_FQDN***
      >
      > For the **nslookup** command, you can use the domain name of any of your nameservers (found in the NS record)

This allows us to resolve the hostname to an IP.


## Point the Registrar to the Authoritative Nameservers
The process varies depending on which registrar you went with. But to use GoDaddy as an example:
  - GoDaddy GUI > navigate to 'Domains' > 'All Domains' > Select your domain.
  - Click on 'Manage DNS'.
  - Update the nameserver(s)/IP's to instead use the 4 provided by AWS. You'll also need to input their IP's (you can ping the nameservers to get their IP's).

    > It can take anywhere from a few minutes, to up to 48 hours for the DNS changes to take effect.

Verify that the configuration is in effect by pinging your domain.


## Update the Gitlab Domain
Back in the docker-compose file in the Gitlab server:
  - Update the **hostname**/**external_url** parameters by swapping the IP for the new domain.
  - Apply the changes:
      > docker-compose down
      >
      > docker-compose up -d

You should now be able to access Gitlab via the domain-name URL. Now to setup SSL!
