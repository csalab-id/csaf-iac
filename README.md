# CSAF Infrastructure as Code
This repository contains Terraform code for managing the infrastructure of the CSAF project using Terraform CLI.

## How to use
For example, to apply the Terraform code with AWS cloud services provider:

```
git clone https://github.com/csalab-id/csaf-iac
cd csaf-iac/aws
export AWS_ACCESS_KEY_ID=A******************I
export AWS_SECRET_ACCESS_KEY=a**************************************I
terraform init
terraform plan
terraform apply
```

To destroy the project you can use this command:

```
cd csaf-iac/aws
terraform destroy
```

This code will generate infrastructure on AWS and subdomain on Cloudflare like

- instance = c5.2xlarge (8core CPU, 16GB RAM)
- region = Singapore
- elastic ip = 3.1.13.7
- security group = open port 22, 6080, 7080, 8080
- VPC = 10.0.0.0/16
- subnet = 10.0.37.0/24

To ensure the installation is finished, you should wait for the process until 1 hour or less.
and you can access the instance with ssh using this command:

```
cd csaf-iac
ssh -i csaf_rsa ubuntu@public_ip
```

To access the CSAF Project you can open this URL on the browser with this URL:

```
http://public_ip:6080/vnc.html (password: attackpassword)
http://public_ip:7080/vnc.html (password: defensepassword)
http://public_ip:8080/vnc.html (password: monitorpassword)
```

For more information, you can see [this](https://github.com/csalab-id/csaf) repository to get more info about the CSAF project.