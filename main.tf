provider "aws" {
 region = "us-east-1"  # Cambia a tu región AWS deseada
}


resource "aws_key_pair" "namdeployer_keye" {
 key_name   = "llavesnake"
 public_key = file("~/.ssh/llavesnake.pub")
}


# Creación de la VPC
resource "aws_vpc" "snake_vpc" {
 cidr_block = "10.0.0.0/16"
 tags = {
   Name = "Snake-VPC"
 }
}


# Internet Gateway para la VPC
resource "aws_internet_gateway" "snake_igw" {
 vpc_id = aws_vpc.snake_vpc.id


 tags = {
   Name = "Snake-Internet-Gateway"
 }
}


# Ruta para el tráfico de Internet
resource "aws_route" "snake_public_internet_route" {
 route_table_id         = aws_vpc.snake_vpc.main_route_table_id
 destination_cidr_block = "0.0.0.0/0"
 gateway_id             = aws_internet_gateway.snake_igw.id
}


# Subnet Pública
resource "aws_subnet" "snake_public_subnet" {
 vpc_id            = aws_vpc.snake_vpc.id
 cidr_block        = "10.0.1.0/24"
 availability_zone = "us-east-1a"
 tags = {
   Name = "Snake-Publica"
 }
}


# Subnet Privada
resource "aws_subnet" "snake_private_subnet" {
 vpc_id            = aws_vpc.snake_vpc.id
 cidr_block        = "10.0.2.0/24"
 availability_zone = "us-east-1b"
 tags = {
   Name = "Snake-Privada"
 }
}


# Security Group para la instancia EC2 en la subnet privada
resource "aws_security_group" "snake_sg" {
 name        = "snake-security-group"
 description = "Security group para la instancia Snake"


 vpc_id = aws_vpc.snake_vpc.id


 ingress {
   from_port   = 22
   to_port     = 22
   protocol    = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
 }


 ingress {
   from_port   = 3000
   to_port     = 3000
   protocol    = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
 }


 egress {
   from_port   = 0
   to_port     = 0
   protocol    = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }
}


# Instancia EC2 en la subnet privada
resource "aws_instance" "snake_instance" {
 ami           = "ami-0bb84b8ffd87024d8"  # Ubuntu 22.04 AMI, cambia según tu región y AMI
 instance_type = "t2.large"
 subnet_id     = aws_subnet.snake_private_subnet.id
 key_name      = "llavesnake"  # Cambia al nombre de tu llave pública en AWS


 security_groups = [aws_security_group.snake_sg.id]


 tags = {
   Name = "Snake-Instance"
 }


 user_data     =<<-EOF
       #!/bin/bash
       sudo apt update
       sudo apt install ufw
       sudo ufw allow 3000
       sudo ufw enable
       sudo apt install docker-compose -y
       git clone https://github.com/dano796/app.git
       cd app/
       sudo docker build -t appsnake:v01 .
       sudo docker run -d -p 3000:3000 appsnake:v01 npm start
       EOF


 # Asociar IP pública, ya que la instancia estará en la subred privada
 associate_public_ip_address = true
}


# Crear un balanceador de cargas clásico en la misma VPC
resource "aws_elb" "snake_elb" {
 name            = "snake-classic-load-balancer"
 subnets         = [aws_subnet.snake_public_subnet.id]  # Ubicar en la subred pública
 security_groups = [aws_security_group.snake_sg.id]  # Usar el mismo grupo de seguridad de la instancia


 listener {
   instance_port     = 3000
   instance_protocol = "HTTP"
   lb_port           = 80
   lb_protocol       = "HTTP"
 }


 instances = [aws_instance.snake_instance.id]


 health_check {
   target              = "HTTP:3000/index.html"
   interval            = 30
   timeout             = 5
   unhealthy_threshold = 2
   healthy_threshold   = 2
 }


 tags = {
   Name = "Snake-Load-Balancer"
 }
}
