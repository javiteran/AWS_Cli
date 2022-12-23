###############################################################################
#       Creación de una VPC, subredes, 
#       internet gateway y tabla de rutas
#      Además creará :
#            - una instancia EC2 Ubuntu Server 22.04
#            - una instancia EC2 Windows Server 2022
#      con IPs elásticas
#      en AWS con AWS CLI
#
# Utilizado para AWS Academy Learning Lab
#
# Autor: Javier Terán González
# Fecha: 06/12/2022
###############################################################################
## Tratamiento de variables de entrada

# Error si el número de parámetros menor o igual que 0
if [ $# -le 0 ]; then
    echo "Hay que introducir el número de alumno NN. (Entre 01 y 99)."
    exit 1
fi
# Error si el parámetro no está entre 01 y 99
if  [ "$1" -gt 0 ] && [ "$1" -le 99 ]; then
    echo "Correcto. Es un número"
else
    echo "Hay que introducir el número de alumno NN. (Entre 01 y 99)." 
    exit 1
fi
#echo "Hola $@!"
NN=$1
echo "Alumno: " $NN;
###############################################################################
AWS_VPC_CIDR_BLOCK=10.22.0.0/16
AWS_Subred1_CIDR_BLOCK=10.22.1$NN.0/24
AWS_Subred2_CIDR_BLOCK=10.22.2$NN.0/24
AWS_IP_UbuntuServer1=10.22.1$NN.100
AWS_IP_UbuntuServer2=10.22.2$NN.100
AWS_Proyecto=g6PHP$NN

echo "######################################################################"
echo "Creación de una VPC, subredes, internet gateway y tabla de rutas."
echo "Además creará una instancia EC2 Ubuntu Server 22.04 y una instancia EC2 Windows Server 2022 con IPs elásticas en AWS con AWS CLI"
echo "Se van a crear con los siguientes valores:"
echo "Alumno:                 " $NN
echo "AWS_VPC_CIDR_BLOCK:     " $AWS_VPC_CIDR_BLOCK
echo "AWS_Subred1_CIDR_BLOCK: " $AWS_Subred1_CIDR_BLOCK
echo "AWS_Subred2_CIDR_BLOCK: " $AWS_Subred2_CIDR_BLOCK
echo "AWS_IP_UbuntuServer1:   " $AWS_IP_UbuntuServer1
echo "AWS_IP_UbuntuServer2:   " $AWS_IP_UbuntuServer2
echo "AWS_Proyecto:           " $AWS_Proyecto
echo "######################################################################"
###############################################################################
## Crear una VPC (Virtual Private Cloud) con su etiqueta
## La VPC tendrá un bloque IPv4 proporcionado por el usuario y uno IPv6 de AWS ???
echo "############## Crear VPC, Subred, Rutas, Gateway #####################"
echo "######################################################################"
echo "Creando VPC..."

AWS_ID_VPC=$(aws ec2 create-vpc \
  --cidr-block $AWS_VPC_CIDR_BLOCK \
  --amazon-provided-ipv6-cidr-block \
  --tag-specification ResourceType=vpc,Tags=[{Key=Name,Value=$AWS_Proyecto-vpc}] \
  --query 'Vpc.{VpcId:VpcId}' \
  --output text)

## Habilitar los nombres DNS para la VPC
aws ec2 modify-vpc-attribute \
  --vpc-id $AWS_ID_VPC \
  --enable-dns-hostnames "{\"Value\":true}"

## Crear subredes publicas con su etiqueta
echo "Creando Subredes..."
AWS_ID_SubredPublica1=$(aws ec2 create-subnet \
  --vpc-id $AWS_ID_VPC --cidr-block $AWS_Subred1_CIDR_BLOCK \
  --availability-zone us-east-1a \
  --tag-specifications ResourceType=subnet,Tags=[{Key=Name,Value=$AWS_Proyecto-subred-publica1}] \
  --query 'Subnet.{SubnetId:SubnetId}' \
  --output text)
AWS_ID_SubredPublica2=$(aws ec2 create-subnet \
  --vpc-id $AWS_ID_VPC --cidr-block $AWS_Subred2_CIDR_BLOCK \
  --availability-zone us-east-1b \
  --tag-specifications ResourceType=subnet,Tags=[{Key=Name,Value=$AWS_Proyecto-subred-publica2}] \
  --query 'Subnet.{SubnetId:SubnetId}' \
  --output text)

## Habilitar la asignación automática de IPs públicas en la subredes públicas
aws ec2 modify-subnet-attribute \
  --subnet-id $AWS_ID_SubredPublica1 \
  --map-public-ip-on-launch
aws ec2 modify-subnet-attribute \
  --subnet-id $AWS_ID_SubredPublica2 \
  --map-public-ip-on-launch


## Crear un Internet Gateway (Puerta de enlace) con su etiqueta
echo "Creando Internet Gateway..."
AWS_ID_InternetGateway=$(aws ec2 create-internet-gateway \
  --tag-specifications ResourceType=internet-gateway,Tags=[{Key=Name,Value=$AWS_Proyecto-igw}] \
  --query 'InternetGateway.{InternetGatewayId:InternetGatewayId}' \
  --output text)

## Asignar el Internet gateway a la VPC
aws ec2 attach-internet-gateway \
--vpc-id $AWS_ID_VPC \
--internet-gateway-id $AWS_ID_InternetGateway

## Crear una tabla de rutas
echo "Creando tabla de rutas..."
AWS_ID_TablaRutas=$(aws ec2 create-route-table \
--vpc-id $AWS_ID_VPC \
--query 'RouteTable.{RouteTableId:RouteTableId}' \
--output text )

## Crear la ruta por defecto a la puerta de enlace IPv4 (Internet Gateway)
echo "     Ruta por defecto IPv4 0.0.0.0/0..."
aws ec2 create-route \
  --route-table-id $AWS_ID_TablaRutas \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $AWS_ID_InternetGateway

## Crear la ruta por defecto a la puerta de enlace IPv4 (Internet Gateway)
echo "     Ruta por defecto IPv6 ::/0..."
aws ec2 create-route --route-table-id  $AWS_ID_TablaRutas \
  --destination-ipv6-cidr-block ::/0 \
  --gateway-id $AWS_ID_InternetGateway

## Asociar la subredes públicas con la tabla de rutas
AWS_ROUTE_TABLE_ASSOID=$(aws ec2 associate-route-table  \
  --subnet-id $AWS_ID_SubredPublica1 \
  --route-table-id $AWS_ID_TablaRutas \
  --output text)
AWS_ROUTE_TABLE_ASSOID=$(aws ec2 associate-route-table  \
  --subnet-id $AWS_ID_SubredPublica2 \
  --route-table-id $AWS_ID_TablaRutas \
  --output text)

## Añadir etiqueta a la ruta por defecto
AWS_DEFAULT_ROUTE_TABLE_ID=$(aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$AWS_ID_VPC" \
  --query 'RouteTables[?Associations[0].Main != `flase`].RouteTableId' \
  --output text) &&
aws ec2 create-tags \
--resources $AWS_DEFAULT_ROUTE_TABLE_ID \
--tags "Key=Name,Value=$AWS_Proyecto ruta por defecto"

## Añadir etiquetas a la tabla de rutas
aws ec2 create-tags \
--resources $AWS_ID_TablaRutas \
--tags "Key=Name,Value=$AWS_Proyecto-rtb-public"


###############################################################################
###############################################################################
###############################################################################
####################       UBUNTU SERVER     ##################################
###############################################################################
###############################################################################
###############################################################################
## Crear un grupo de seguridad Ubuntu Server
echo "########################### Ubuntu Server ############################"
echo "######################################################################"
echo "Creando grupo de seguridad Ubuntu Server..."
AWS_ID_GrupoSeguridad_Ubuntu=$(aws ec2 create-security-group \
  --vpc-id $AWS_ID_VPC \
  --group-name $AWS_Proyecto-us-sg \
  --description "$AWS_Proyecto-us-sg" \
  --output text)

echo "ID Grupo de seguridad de ubuntu: " $AWS_ID_GrupoSeguridad_Ubuntu

echo "Añadiendo reglas de seguridad al grupo de seguridad Ubuntu Server..."
## Abrir los puertos de acceso a la instancia
aws ec2 authorize-security-group-ingress \
  --group-id $AWS_ID_GrupoSeguridad_Ubuntu \
  --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 22, "ToPort": 22, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow SSH"}]}]'

aws ec2 authorize-security-group-ingress \
  --group-id $AWS_ID_GrupoSeguridad_Ubuntu \
  --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 80, "ToPort": 80, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow HTTP"}]}]'

## Añadirle etiqueta al grupo de seguridad
echo "Añadiendo etiqueta al grupo de seguridad Ubuntu Server..."
aws ec2 create-tags \
--resources $AWS_ID_GrupoSeguridad_Ubuntu \
--tags "Key=Name,Value=$AWS_Proyecto-us-sg" 

###############################################################################
###############################################################################
###############################################################################
###############################################################################
## Crear instancia EC2 -1  (con una imagen de ubuntu 22.04 del 04/07/2022)
echo ""
echo "Creando instancia EC2 Ubuntu  ##################################"
AWS_AMI_Ubuntu_ID=ami-052efd3df9dad4825
AWS_EC2_INSTANCE_ID1=$(aws ec2 run-instances \
  --image-id $AWS_AMI_Ubuntu_ID \
  --instance-type t2.micro \
  --key-name vockey \
  --monitoring "Enabled=false" \
  --security-group-ids $AWS_ID_GrupoSeguridad_Ubuntu \
  --subnet-id $AWS_ID_SubredPublica1 \
  --user-data file://10LabPHP_userdata.txt \
  --private-ip-address $AWS_IP_UbuntuServer1 \
  --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=$AWS_Proyecto-us1}] \
  --query 'Instances[0].InstanceId' \
  --output text)

#echo $AWS_EC2_INSTANCE_ID1
###############################################################################
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
--tags Key=Name,Value=$AWS_Proyecto-us1-ip

###############################################################################
## Asociar la ip elastica a la instancia Ubuntu
echo "Esperando a que la instancia esté disponible para asociar la IP elastica"
sleep 100
aws ec2 associate-address --instance-id $AWS_EC2_INSTANCE_ID1 --allocation-id $AWS_IP_Fija_UbuntuServer_AllocationId


###############################################################################
###############################################################################
###############################################################################
###############################################################################
## Crear instancia EC2 -2  (con una imagen de ubuntu 22.04 del 04/07/2022)
echo ""
echo "Creando instancia EC2 Ubuntu  ##################################"
AWS_AMI_Ubuntu_ID=ami-052efd3df9dad4825
AWS_EC2_INSTANCE_ID2=$(aws ec2 run-instances \
  --image-id $AWS_AMI_Ubuntu_ID \
  --instance-type t2.micro \
  --key-name vockey \
  --monitoring "Enabled=false" \
  --security-group-ids $AWS_ID_GrupoSeguridad_Ubuntu \
  --subnet-id $AWS_ID_SubredPublica2 \
  --user-data file://10LabPHP_userdata.txt \
  --private-ip-address $AWS_IP_UbuntuServer2 \
  --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=$AWS_Proyecto-us2}] \
  --query 'Instances[0].InstanceId' \
  --output text)

#echo $AWS_EC2_INSTANCE_ID2
###############################################################################
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
--tags Key=Name,Value=$AWS_Proyecto-us2-ip

###############################################################################
## Asociar la ip elastica a la instancia Ubuntu
echo "Esperando a que la instancia esté disponible para asociar la IP elastica"
sleep 100
aws ec2 associate-address --instance-id $AWS_EC2_INSTANCE_ID2 --allocation-id $AWS_IP_Fija_UbuntuServer_AllocationId


###############################################################################
## Mostrar las ips publicas de las instancias
echo "Mostrando las ips publicas de las instancias"
AWS_EC2_INSTANCE_PUBLIC_IP=$(aws ec2 describe-instances \
--query "Reservations[*].Instances[*].PublicIpAddress" \
--output=text) &&
echo $AWS_EC2_INSTANCE_PUBLIC_IP
###############################################################################


###############################################################################
###############################################################################
###########          BALANCEO DE CARGA ELB    #################################
###############################################################################
###############################################################################
# Crear el balanceador
AWS_ELB=$(aws elbv2 create-load-balancer \
    --name $AWS_Proyecto-elb \
    --type application \
    --subnets $AWS_ID_SubredPublica1 $AWS_ID_SubredPublica2 \
    --security-groups $AWS_ID_GrupoSeguridad_Ubuntu \
    --output=text)
echo "ELB"
echo $AWS_ELB | awk '{print $6}'
AWS_ELB_arn=$(echo $AWS_ELB | awk '{print $6}')

###################################################
#https://docs.aws.amazon.com/cli/latest/reference/elbv2/create-target-group.html
AWS_TargetGroup=$(aws elbv2 create-target-group \
    --name $AWS_Proyecto-targets \
    --protocol HTTP \
    --port 80 \
    --target-type instance \
    --vpc-id $AWS_ID_VPC \
    --output=text)
echo "Target Group"
echo $AWS_TargetGroup | awk '{print $12}'
$AWS_TargetGroup_arn=$(echo $AWS_TargetGroup | awk '{print $12}')

#https://docs.aws.amazon.com/cli/latest/reference/elbv2/register-targets.html
aws elbv2 register-targets \
    --target-group-arn $AWS_TargetGroup \
    --targets Id=$AWS_EC2_INSTANCE_ID1 Id=$AWS_EC2_INSTANCE_ID2

###################################################
#Crear listener y asociar el balanceador con el target-group
aws elbv2 create-listener \
    --load-balancer-arn $AWS_ELB_arn \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=$AWS_TargetGroup_arn
###################################################
        