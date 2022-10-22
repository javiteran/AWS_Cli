## Crear un grupo de seguridad etiquetado y añadirle las reglas de entrada
sg=$(aws ec2 create-security-group \
  --vpc-id vpc-0270518bf745163ff \
  --group-name SRINN-sg \
  --tag-specifications 'ResourceType=security-group,Tags=[{Key='Name',Value='SRINN-sg'}]' \
  --description 'Grupo de seguridad SRINN-sg' \
  --output text)

echo $sg
AWS_sg_Id=$(echo $sg | awk '{print $1}')


aws ec2 authorize-security-group-ingress \
  --group-id $AWS_sg_Id \
  --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 22, "ToPort": 22, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow SSH"}]}]' 

