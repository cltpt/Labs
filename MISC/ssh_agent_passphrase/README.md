## Table of Contents

- [Introduction](#introduction)
- [Better options](#better-options)
- [Instructions (Click here to skip the explanations)](#instructions)

## Introduction

One of the $\textcolor{red}{\textsf{main discussion points}}$ I witness when talking with developers about utilizing encrypted (passphrase protected) SSH private keys is "I $\textcolor{red}{\textsf{can't encrypt my ssh private key}}$ because I use it in $\textcolor{red}{\textsf{automated scripts}}$".  We're here to $\textcolor{red}{\textsf{solve a portion}}$ of that discussion point.

### Background on ssh-agent

SSH-Agent is a $\textcolor{red}{\textsf{crucial tool for software developers}}$ that enhances security and $\textcolor{red}{\textsf{simplifies}}$ the process of $\textcolor{red}{\textsf{working with SSH}}$ (Secure Shell) keys. SSH-Agent acts as a secure storage system for your private SSH keys, $\textcolor{red}{\textsf{eliminating}}$ the need to $\textcolor{red}{\textsf{repeatedly enter your passphrase}}$ whenever you want to establish a secure connection. When you add your private key to the SSH-Agent, it securely holds the key in memory, allowing you to authenticate with remote servers without providing the passphrase every time.

By utilizing SSH-Agent, software developers can enjoy $\textcolor{red}{\textsf{several benefits}}$. First and foremost, it improves convenience by $\textcolor{red}{\textsf{eliminating}}$ the need to $\textcolor{red}{\textsf{repeatedly enter passphrases}}$, thereby saving time and effort. Once the private key is added to the SSH-Agent, it remains active until the system restarts or the user manually removes it. This means that developers can authenticate with various remote servers or repositories seamlessly, without interruption. Additionally, SSH-Agent enhances security by reducing the risk of passphrase exposure. Since the $\textcolor{red}{\textsf{private key remains in memory}}$ and is never transmitted, developers can $\textcolor{red}{\textsf{avoid the potential vulnerability}}$ of passphrases being intercepted or compromised.

In summary, SSH-Agent simplifies the life of software developers by $\textcolor{red}{\textsf{securely storing private SSH keys}}$, eliminating the need to repeatedly enter passphrases, and providing a seamless and secure authentication experience when connecting to remote servers or repositories. It streamlines the workflow, enhances convenience, and reduces the risk of passphrase exposure, allowing developers to focus on their work without compromising security.

## Better Options

If you're utilizing a $\textcolor{red}{\textsf{cloud environment, this guide is likely not for you}}$.  For example, in an AWS environment with EC2 instances it is less efficent to run batch jobs / automated scripts directly from the EC2 instances.  If you're pulling data from a resource and transferring it, processing data, or simply running an automated job to do something, use a Lambda function and schedule it using AWS EventBridge.  This is a much more effective method of automated jobs rather than utilizing an EC2 instance and running jobs off the EC2 instance.

Read more about how to utilize AWS Lambda, AWS EventBridge and IAM roles here:

* **AWS EventBridge:** [AWS EventBridge Documentation](https://docs.aws.amazon.com/eventbridge/)
    EventBridge is a serverless event bus service provided by AWS. It allows you to build event-driven architectures by integrating various AWS services and custom applications.

* **AWS Lambda:** [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
    AWS Lambda is a serverless compute service provided by AWS. It allows you to run your code without provisioning or managing servers. You can use Lambda to build and run serverless applications.

* **AWS IAM Roles:** [AWS IAM Roles Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html)
    AWS Identity and Access Management (IAM) roles are a way to manage permissions and access control for AWS resources. IAM roles allow you to delegate access to AWS services and resources securely.

## Instructions

### IMPORTANT Considerations
$\textcolor{red}{\textsf{Please do not attempt to utilize this terraform code in a production environment, this is meant for testing only.}}$ 
* If you want to utilize the ssh-agent for reduced passphrase input, please test in a sandbox environment and then into a staging or non-production environment before you deploy into a production environment.
* If you deploy this strategy into a production environment, ensure that you have some form of reminder to insert the private key at system boot time


### Pre-requsites
1. Have an AWS account in which you have access to create resources and manage IAM
2. Have terraform installed on your local system [Terraform install docs](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)S
3. Have AWS CLI installed on your local system to configure your access and secret keys [AWS CLI Install docs](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

### Steps
1. Generate an EC2 key pair
2. Edit the *ec2_client_deployment.tf* file and add in the private key where it says _insertyourrsakeyhere_
3. Run the Terraform scripts
4. Encrypt your private key
5. Follow the code samples to start ssh-agent and add in the key
6. Automate the starting of ssh-agent and the addition of your private key into your bashrc file

### Step 1: Generate an EC2 key pair
1. Login to AWS Management Console
2. Navigate to the EC2 service
3. Scroll down on the left hand side of your page to "Key Pairs"
4. Generate a new key pair (ED25519 and .pem options) and give it a memorable name (EX: testing_ec2_keypair_ssh_agent)
5. It should have auto-downloaded your private key, you're done with Step 1

### Step 2: Edit the *ec2_client_deployment.tf* file and add in the private key where it says _insertyourrsakeyhere_
1. Take your newly downloaded private key and open it up in a text editor of your choice
2. Copy the key into your clipboard, with the -----BEGIN OPENSSH PRIVATE KEY----- and -----END OPENSSH PRIVATE KEY----- lines included
3. Open the *ec2_client_deployment.tf* file and find where it says _insertyourrsakeyhere_ and paste your private key in there, leaving the single quotes

### Step 3: Run the Terraform scripts
1. If you haven't already configured your AWS Access and Secret keys run the following command (it will ask you to enter in your access and secret keys)
aws configure
'''
2. In your terminal run the following sequence of commands to run your Terraform code
```hcl
terraform init
terraform validate
terraform apply
```

### Step 4. Encrypt your private key
1. To encrypt your private key navigate to the directory created in the Terraform scripts (/mykeys)
```
cd /mykeys
```
2. Change the file permissions of the key so the ssh-keygen command doesn't yell at you and change ownership
```
sudo chmod 700 mykey_rsa
sudo chown ssm-user mykey_rsa
```
3. Encrypt the key utilizing this command, and set a passphrase (since this is a demo choose something easy to remember)
```
ssh-keygen -p -f /mykeys/mykey_rsa
```

### Step 5: Follow the code samples to start ssh-agent and add in the key
1. First before you add in the code it's useful to see what happens without ssh-agent.  SSH to the "server" by obtaining the private IP address of the server (find it in the management console) and then running the following command.  Once you've ssh'd into it, exit the session by typing "exit" and then hit the enter key.  Once you've completed those steps, run it again and notice how you have to enter in the 
```
ssh -i mykey_rsa ec2-user@yourserversiphere
```
2. To start the ssh-agent run the following command
```
eval $(ssh-agent -s)
```
3. To add your key into ssh agent run the following command (you should already be in the /mykeys directory)
```
ssh-add mykey_rsa
```
4. Now that you've added in the key into ssh-agent you can ssh to the other server by only entering in the passphrase once!  You can ssh to the other server, exit the session and then ssh into it again noticing that you're not prompted for a passphrase!

### Step 6: Automate the starting of ssh-agent and the addition of your private key into your bashrc file
1. Edit your .bashrc file by opening it with your favorite text editor
```
nano ~/.bashrc
```
2. Page down to the bottom of your .bashrc file and add the following code (When you paste it in, ensure you get the proper spacing and tabs otherwise loading the source will not work)
```
if ! ps -ef | grep "[s]sh-agent" &>/dev/null; then
		echo Starting SSH Agent
		eval $(ssh-agent -s)
fi
		
if ! ssh-add -l $>/dev/null; then
		echo Adding keys....
		ssh-add /mykeys/mykey_rsa
fi
```
3. Load your new .bashrc file with the source command
```
source ~/.bashrc
```
4. Now that you've added it into your .bashrc file it will prompt you at every reboot for the passphrase to your key

## Final thoughts
Thank you for going through this lab today!  If you have any comments, suggestions, etc, please open a pull request and collaborate.