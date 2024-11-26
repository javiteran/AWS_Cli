# :dizzy: Tareas en AWS Academy con AWS CLI

Cuando utilizamos AWS Academy y su learner lab puede interesarnos personalizar el entorno de los alumnos.

Muestra una posible solución de automatización de la creación de entornos de tareas en AWS con AWS CLI.

## :gear: Referencia de comandos AWS CLI

https://awscli.amazonaws.com/v2/documentation/api/latest/reference/ec2/index.html#cli-aws-ec2

## :collision: Configuración del entorno en el Learner Lab

![ConfigurarEntornoLearnerLab.PNG](imagenes/ConfigurarEntornoLearnerLab.PNG)

## :hammer: Creación de entorno de tareas 00AWSCrearVPC_EC2Win_Ubu.sh

```git
git clone https://github.com/javiteran/AWS_Cli.git
cd AWS_Cli
. 00AWSCrearVPC_EC2Win_Ubu.sh
```

Con este fichero se creará el siguiente entorno de tareas:

![00AWSCrearVPC_EC2Win_Ubu.PNG](imagenes/00AWSCrearVPC_EC2Win_Ubu.PNG)

Creará:

* Una VPC con IPv4 e IPv6
* Una subred pública
* Una puerta de enlace de internet
* La tabla de enrutamiento de la subred para permitir conectarse a internet
* Un grupo de seguridad para Ubuntu y otro para Windows.
* Se abrirán los puertos 80, 22 y 3389 para Ubuntu y Windows respectivamente. (y el 53 para DNS como práctica inicial tanto en IPv4 como en IPv6)
* Se permitirá todo el tráfico entre las instancias de la VPC
* Una instancia EC2 con Windows Server 2022 
* Una instancia EC2 con Ubuntu Server 24.04
* En Ubuntu y Windows se instalarán servicios y roles como DNS para probar la instalación en la creación
* Direcciones IPv4s e IPv6s públicas para las instancias EC2

## Hacer lo mismo con IPv4 e IPv6 pero con un parámetro de entrada que será el NN del alumno

```git
git clone https://github.com/javiteran/AWS_Cli.git
cd AWS_Cli
sh 00AWSLab01_IPv4_IPv6.sh 15 
```


## Hacer lo mismo sólo con IPv4 pero con un parámetro de entrada que será el NN del alumno

```git
git clone https://github.com/javiteran/AWS_Cli.git
cd AWS_Cli
sh 00AWSLab01_IPv4.sh 15 
```


## Hacer lo mismo con Python3 y Boto3

Puedes buscar documentación para hacer los mismo con python3 en la siguiente web.
https://boto3.amazonaws.com/v1/documentation/api/latest/guide/examples.html


## Microsoft Visio de la tarea

En la carpeta MicrosoftVisio se encuentra el fichero de la tarea para poder editarlo o modificarlo.
