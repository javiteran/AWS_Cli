##########################################################
## Crear IP Estatica para la instancia Ubuntu. (IP elastica)
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
aws ec2 associate-address --instance-id $AWS_EC2_INSTANCE_ID --allocation-id $AWS_IP_Fija_UbuntuServer_AllocationId