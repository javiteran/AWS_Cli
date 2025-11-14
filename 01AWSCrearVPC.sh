###########################################################
#       Creación de una VPC, subredes, 
#       internet gateway y tabla de rutas
#      en AWS con AWS CLI
#
# Utilizado para AWS Academy Learning Lab
#
# Autor: Javier Terán González
# Fecha: 18/10/2022
#        14/11/2025. Cambiar AMIs de Ubuntu y Windows
###########################################################

## Definición de variables
AWS_VPC_CIDR_BLOCK=10.25.0.0/16
AWS_Subred_CIDR_BLOCK=10.25.130.0/24
AWS_IP_UbuntuServer=10.25.130.100
AWS_IP_WindowsServer=10.25.130.200

###########################################################
## Crear una VPC (Virtual Private Cloud) con su etiqueta
## La VPC tendrá un bloque IPv4 proporcionado por el usuario y uno IPv6 de AWS ???
echo "Creando VPC..."
AWS_ID_VPC=$(aws ec2 create-vpc \
  --cidr-block $AWS_VPC_CIDR_BLOCK \
  --amazon-provided-ipv6-cidr-block \
  --tag-specification ResourceType=vpc,Tags=[{Key=Name,Value=SRINN-vpc}] \
  --query 'Vpc.{VpcId:VpcId}' \
  --output text)

## Habilitar los nombres DNS para la VPC
aws ec2 modify-vpc-attribute \
  --vpc-id $AWS_ID_VPC \
  --enable-dns-hostnames "{\"Value\":true}"

## Crear una subred publica con su etiqueta
AWS_ID_SubredPublica=$(aws ec2 create-subnet \
  --vpc-id $AWS_ID_VPC --cidr-block $AWS_Subred_CIDR_BLOCK \
  --availability-zone us-east-1a \
  --tag-specifications ResourceType=subnet,Tags=[{Key=Name,Value=SRINN-subred-publica}] \
  --query 'Subnet.{SubnetId:SubnetId}' \
  --output text)

## Habilitar la asignación automática de IPs públicas en la subred pública
aws ec2 modify-subnet-attribute \
  --subnet-id $AWS_ID_SubredPublica \
  --map-public-ip-on-launch

## Crear un Internet Gateway (Puerta de enlace) con su etiqueta
AWS_ID_InternetGateway=$(aws ec2 create-internet-gateway \
  --tag-specifications ResourceType=internet-gateway,Tags=[{Key=Name,Value=SRINN-igw}] \
  --query 'InternetGateway.{InternetGatewayId:InternetGatewayId}' \
  --output text)

## Asignar el Internet gateway a la VPC
aws ec2 attach-internet-gateway \
--vpc-id $AWS_ID_VPC \
--internet-gateway-id $AWS_ID_InternetGateway

## Crear una tabla de rutas
AWS_ID_TablaRutas=$(aws ec2 create-route-table \
--vpc-id $AWS_ID_VPC \
--query 'RouteTable.{RouteTableId:RouteTableId}' \
--output text )

## Crear la ruta por defecto a la puerta de enlace (Internet Gateway)
aws ec2 create-route \
  --route-table-id $AWS_ID_TablaRutas \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $AWS_ID_InternetGateway

## Asociar la subred pública con la tabla de rutas
AWS_ROUTE_TABLE_ASSOID=$(aws ec2 associate-route-table  \
  --subnet-id $AWS_ID_SubredPublica \
  --route-table-id $AWS_ID_TablaRutas \
  --output text)

## Añadir etiqueta a la ruta por defecto
AWS_DEFAULT_ROUTE_TABLE_ID=$(aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$AWS_ID_VPC" \
  --query 'RouteTables[?Associations[0].Main != `flase`].RouteTableId' \
  --output text) &&
aws ec2 create-tags \
--resources $AWS_DEFAULT_ROUTE_TABLE_ID \
--tags "Key=Name,Value=SRINN ruta por defecto"

## Añadir etiquetas a la tabla de rutas
aws ec2 create-tags \
--resources $AWS_ID_TablaRutas \
--tags "Key=Name,Value=SRINN-rtb-public"


###########################################################
## Crear un grupo de seguridad Ubuntu Server
echo "Creando grupo de seguridad Ubuntu Server..."
aws ec2 create-security-group \
  --vpc-id $AWS_ID_VPC \
  --group-name SRINNus-sg \
  --description 'Grupo de seguridad SRINNus-sg'


AWS_CUSTOM_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=$AWS_ID_VPC" \
  --query 'SecurityGroups[?GroupName == `SRINNus-sg`].GroupId' \
  --output text)

## Abrir los puertos de acceso a la instancia
aws ec2 authorize-security-group-ingress \
  --group-id $AWS_CUSTOM_SECURITY_GROUP_ID \
  --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 22, "ToPort": 22, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow SSH"}]}]'

aws ec2 authorize-security-group-ingress \
  --group-id $AWS_CUSTOM_SECURITY_GROUP_ID \
  --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 80, "ToPort": 80, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow HTTP"}]}]'


## Añadirle etiqueta al grupo de seguridad
aws ec2 create-tags \
--resources $AWS_CUSTOM_SECURITY_GROUP_ID \
--tags "Key=Name,Value=SRINNus-sg" 

###########################################################
## Crear una instancia EC2  (con una imagen de ubuntu 24.04)
echo "Creando instancia EC2 Ubuntu"
AWS_AMI_Ubuntu_ID=ami-0ecb62995f68bb549
AWS_EC2_INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AWS_AMI_Ubuntu_ID \
  --instance-type t2.micro \
  --key-name vockey \
  --monitoring "Enabled=false" \
  --security-group-ids $AWS_CUSTOM_SECURITY_GROUP_ID \
  --subnet-id $AWS_ID_SubredPublica \
  --user-data file://datosusuarioUbuntu.txt \
  --private-ip-address $AWS_IP_UbuntuServer \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=SRINNus}]' \
  --query 'Instances[0].InstanceId' \
  --output text)

#echo $AWS_EC2_INSTANCE_ID
###########################################################
## Crear IP Estatica para la instancia Ubuntu. (IP elastica)
echo "Creando IP elastica Ubuntu"
AWS_IP_Fija_UbuntuServer=$(aws ec2 allocate-address --output text)
echo $AWS_IP_Fija_UbuntuServer 

## Recuperar AllocationId de la IP elastica
AWS_IP_Fija_UbuntuServer_AllocationId=$(echo $AWS_IP_Fija_UbuntuServer | awk '{print $1}')
echo $AWS_IP_Fija_UbuntuServer_AllocationId

## Añadirle etiqueta a la ip elástica de Ubuntu
aws ec2 create-tags \
--resources $AWS_IP_Fija_UbuntuServer_AllocationId \
--tags "Key=Name,Value=SRINNus-ip" 

##########################################################
## Asociar la ip elastica a la instancia Ubuntu
echo "Esperando a que la instancia esté disponible para asociar la IP elastica"
sleep 15
aws ec2 associate-address --instance-id $AWS_EC2_INSTANCE_ID --allocation-id $AWS_IP_Fija_UbuntuServer_AllocationId


##########################################################
## Mostrar las ips publicas de las instancias
echo "Mostrando las ips publicas de las instancias"
AWS_EC2_INSTANCE_PUBLIC_IP=$(aws ec2 describe-instances \
--query "Reservations[*].Instances[*].PublicIpAddress" \
--output=text) &&
echo $AWS_EC2_INSTANCE_PUBLIC_IP
##########################################################