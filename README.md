# GitLab Setup
---

Step-by-step instructions on setting up a Gitlab Environment and Pipeline.

Clone this repo and go through the directories below in order to setup Gitlab....


# aws_infrastructure
Deploy this terraform template into the account to deploy:
  - A VPC
  - 2 EC2 instances, both publicly accessible and with docker pre-installed
  - 1 instance will has an EIP attached and will be used to host the Gitlab Instance
  - The other instance will host the Runner

  > Pre-Requisites:
  > An EC2 key pair (since it can't be created programmatically) for the 2 EC2 instances.

Steps:
  - Create an EC2 keypair
  - Run 'aws-configure' to ensure your CLI can log into your AWS account.
  - cd into this directory (make sure you have Terraform installed)
  - Run terraform init
  - Run terraform apply


# gitlab-instance
Contains a Docker-Compose file that deploys a Gitlab image. This will be deployed into the instance with the EIP.

Steps:
  - Copy the docker-compose file.
  - SSH into the EC2 instance.
  - Create a file called "docker-compose.yml" and paste these contents into it.
    - The file can be placed anywhere on the machine.
    - Swap the hostname/external_url values with the public IP of the EC2 instance.
  - In the same directory where you have created the file, run:
    > docker-compose up -d
  - Verify that the container is running:
    > docker ps (wait until the Status is 'healthy')
  - If there are any errors, check the real-time logs:
    > docker logs -f gitlab

You should now be able to access the Gitlab instance from your browser (if you can't, you may need to reboot the instance first).
  > You'll be prompted to change your password.
  > The username is 'root'.

Next, we will setup the domain, DNS, and SSL.


# dns-setup
Follow the README to setup DNS for Gitlab.


# ssl-setup
Follow the README to setup SSL.


# gitlab-runner
Follow the README instructions to deploy, configure and register a runner.


# ssh-setup
Follow the README instructions to setup SSH connectivity to your GitLab instance so that you can clone code from it.

NOTE: you will need to create a new SSH key (unique to GitLab) if you already have one you use for something else. These instructions will go over that.


## simple-pipeline
This is a simple pipeline just to play with. It is executed by the runner and gets us familiar with the process of kicking off pipelines.

This particular pipeline contains 2 jobs:
  - The build job will simply create a folder containing a text file and writes to it.
  - The test job checks for the existence of this new folder/file and ensures the correct text was written to the file.
  - The resulting artifact is passed back to GitLab and is downloadable in the GUI.

This pipeline will run automatically once it's committed to your Gitlab project (the one that we've attached the runner to). It will then kick-off upon any subsequent commit to the project.

Steps:
  1. Clone your test project down locally if you haven't already.
  2. Copy/paste the gitlab-ci.yml file (in this simple-pipeline directory) into the base of your project and commit it.
    > git add .
    > git commit -m "fist commit"
    > git push origin master
  3. The pipeline will now kick off. You can monitor it's progress.
    > In your GitLab project in the console > CI/CD > Pipelines
    > You can also click on Jobs, to view the actual jobs running within the pipeline.


## test-ecr-pipeline
This is a slightly more interesting pipeline that lets us build a Docker image and push it to a registry (in our case, AWS ECR).


Background:
GitLab runners are capable of implementing different types of "executors" to run your builds.
  > For example, there is a shell executor and a docker executor. The former is easier to configure but requires you to manually install all your build's dependencies up-front (including Docker). The latter provides a clean build environment and easier dependency-management.
  > We used the Docker executor in the setup of our runner.

If you want your CI/CD pipeline to build/test/deploy docker images, there are several way to enable the use of docker commands in your builds. If you're using the docker executor, you can bind the /var/run/docker.sock mount to the runner container when deploying/registering it. This makes the Docker engine (installed on our EC2 instance) available in the context of the runner-container.
  > This is the way we've done it (you can verify in the gitlab-runner directory that we are using the docker executor and mounting /var/run/docker.sock to the container)

At a high-level this pipeline will:
  - Use the docker executor to pull the latest docker image (declared at the top of the .gitlab-ci.yml pipeline script)
  - Run a new container based off that image and clone your repo code into it.
  - Run a pre-job script to install some dependencies and login to ECR.
  - Execute the build job to build your local Dockerfile into an image, tag it with the latest commit ID, and push it up to your ECR repo.

Steps:
  1. Create a repository in AWS ECR
    > When prompted to enter a repo name, you can optionally prepend a namespace to the repo-name, with the convention <namespace-name>/<repo-name>. This is a good way to organize your repos.
    > Ex: example-namespace/example-repo
  2. Create a new project in GitLab for our ECR pipeline and clone it locally. Copy the test-ecr-pipeline directory files into the base of the project.
    > Make sure to modify the repo-URL variable in .gitlab-ci.ymal to your ECR URI.
  3. Enable the runner for this new project:
    > Navigate to your new project in the GUI > Settings > CI/CD > Runners > Scroll down to the runner and click "enable for this project"
  4. Before we commit anything to the repo and kick off the pipeline, we need to set the environment variables for our project to use our AWS account credentials.
    - Create an IAM user with AmazonEC2ContainerRegistryFullAccess and AmazonEC2ContainerServiceFullAccess policies attached.
    - In your project > Settings > CI/CD > Variables > Expand > Create AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY variables.
  4. Commit your code to the repo and let the pipeline kick off.
