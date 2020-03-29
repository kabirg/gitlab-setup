# Setup SSH to Clone Repo's

We now need to be able to SSH into GitLab instance so that we can clone our repo's.

2 things to keep in mind:
  1. We need to SSH using port 2222
  2. We need to create an SSH key (if we already have one, we'll have to create a new one unique to Gitlab)

*(Both of these are elaborated on below)*

## 1 - The SSH Port
The reason we SSH into port 2222 is because we mapped the GitLab container's port-22 to the host's port-2222.
  - Since the SSHD service is already listening on port 22 on the host, you can't map the container's port to that port (since it's already in use). Hence why we mapped it to 2222.
  - The docker-compose file's ***gitlab_rails['gitlab_shell_ssh_port']*** OMNIBUS config directs our SSH requests to port 2222.
      > **GITLAB_OMNIBUS_CONFIG** is a parameter of the gitlab-container-deployment command that accepts a variety of arguments, which all directly modify **gitlab.rb** (GitLab's central configuration file)


## 2 - Creating a Unique SSH Key
GitLab supports the following types of keypairs:
  - RSA
  - DSA
  - ECDSA
  - ED25519

We'll go with RSA since it's the most common.

Go with option 1 or 2 below based on whether or not you have an existing SSH key.

By the end, you should be able to run the following to validate SSH connectivity:
    ssh -T git@example.com -p 2222

You should get a message saying:
  > Welcome to GitLab, @<USERNAME>!


### Option 1 - If you don't already have an SSH key
  - Generate a new SSH key
      > ssh-keygen -t rsa -b 4096 -C "email@example.com"
  - Use all the default values when prompted.
  - Copy the contents of **id_rsa.pub** (the public key)
  - GitLab Console > Settings > SSH Keys > paste your key and save.


### Option 2 - If you already have a SSH key
Public SSH keys will bind to your GitLab account. For that reason they need to be unique to GitLab. So if you already have a private key we'll need to create a new one.

  - Generate a new SSH key
      > ssh-keygen -t rsa -b 4096 -C "email@example.com"
  - Use a new directory to store this key into, when prompted
      > **/Users/<NAME>/.ssh/gitlab** <-- is what I used.
  - Load this new key into the SSH agent:
      > eval "$(ssh-agent -s)"
      > ssh-add ~/.ssh/gitlab/id_rsa
  - We also need to persist this setting by adding it to a config file:
    - Create a file named ***config*** in your **~/.ssh** directory.
    - In the file add the following contents:
          > # Private GitLab instance
          > Host example.com
          >   Preferredauthentications publickey
          >   IdentityFile ~/.ssh/gitlab/id_rsa
    - Make sure to point **Host** to your domain.


You should now be able to validate SSH connectivity and clone repo's from your GitLab instance.
    > ssh -T git@example.com -p 2222
