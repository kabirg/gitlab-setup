sudo docker run --detach \
  --hostname YOUR_PUBLIC_IP \
  --env GITLAB_OMNIBUS_CONFIG="external_url 'http://YOUR_PUBLIC_IP'; gitlab_rails['gitlab_shell_ssh_port'] = 2222;" \
  --publish 443:443 --publish 80:80 --publish 2222:22 \
  --name gitlab \
  --restart always \
  --volume /srv/gitlab/config:/etc/gitlab \
  --volume /srv/gitlab/logs:/var/log/gitlab \
  --volume /srv/gitlab/data:/var/opt/gitlab \
  gitlab/gitlab-ce:latest
