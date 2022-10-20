###########################################################
#       Creación de una instancia EC2
#       con sus grupos de seguridad y puertos abiertos
#      en AWS con AWS CLI
#
# Utilizado para AWS Academy Learning Lab
#
# Autor: Javier Terán González
# Fecha: 20/10/2022
###########################################################


AWS_IP_UbuntuServer=10.22.130.100
AWS_IP_WindowsServer=10.22.130.200

## Create a security group
aws ec2 create-security-group \
  --vpc-id $AWS_VPC_ID \
  --group-name myvpc-security-group \
  --description 'My VPC non default security group'

## Get security group ID's
AWS_DEFAULT_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=$AWS_VPC_ID" \
  --query 'SecurityGroups[?GroupName == `default`].GroupId' \
  --output text) &&
  AWS_CUSTOM_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=$AWS_VPC_ID" \
  --query 'SecurityGroups[?GroupName == `myvpc-security-group`].GroupId' \
  --output text)

## Create security group ingress rules
aws ec2 authorize-security-group-ingress \
  --group-id $AWS_CUSTOM_SECURITY_GROUP_ID \
  --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 22, "ToPort": 22, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow SSH"}]}]' &&

aws ec2 authorize-security-group-ingress \
  --group-id $AWS_CUSTOM_SECURITY_GROUP_ID \
  --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 80, "ToPort": 80, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow HTTP"}]}]'



## Add a tags to security groups
aws ec2 create-tags \
--resources $AWS_CUSTOM_SECURITY_GROUP_ID \
--tags "Key=Name,Value=myvpc-security-group" &&
aws ec2 create-tags \
--resources $AWS_DEFAULT_SECURITY_GROUP_ID \
--tags "Key=Name,Value=myvpc-default-security-group"


## Crear datos de usuario para Apache/PHP/Mariadb
vi myuserdata.txt
-----------------------
#!/bin/bash
sudo apt update -y
sudo apt install -y apache2 mariadb-server
sudo apt install -y php
sudo systemctl start apache2
sudo systemctl is-enabled apache2
-----------------------
:wq


## Create an EC2 instance (con una imagen de ubuntu 22.04 del 04/07/2022)
AWS_AMI_ID=ami-052efd3df9dad4825
#AWS_SUBNET_PUBLIC_ID=subnet-089fd47ce4cec8ff1
AWS_EC2_INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AWS_AMI_ID \
  --instance-type t2.micro \
  --key-name vockey \
  --monitoring "Enabled=false" \
  --security-group-ids $AWS_CUSTOM_SECURITY_GROUP_ID \
  --subnet-id $AWS_SUBNET_PUBLIC_ID \
  --user-data file://myuserdata.txt \
  --private-ip-address $AWS_IP_UbuntuServer \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=webserver,Value=SRIXX-Ubuntu}]'
  --query 'Instances[0].InstanceId' \
  --output text)


## Get the public ip address of your instance
AWS_EC2_INSTANCE_PUBLIC_IP=$(aws ec2 describe-instances \
--query "Reservations[*].Instances[*].PublicIpAddress" \
--output=text) &&
echo $AWS_EC2_INSTANCE_PUBLIC_IP

## Try to connect to the instance
#chmod 400 myvpc-keypair.pem
#ssh -i myvpc-keypair.pem ec2-user@$AWS_EC2_INSTANCE_PUBLIC_IP
#exit



#aws ec2 allocate-address
#aws ec2 associate-address --instance-id i-07ffe74c7330ebf53
#aws ec2 associate-address --instance-id i-0b263919b6498b123 --allocation-id eipalloc-64d5890a

aws ec2 describe-addresses

#aws ec2 delete-vpc --vpc-id vpc-??????