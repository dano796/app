provider "aws" {
  region = "us-east-1"  # Cambia a tu región AWS deseada
}

resource "aws_key_pair" "deployer_key" {
  key_name   = "llaveTetris"
  public_key = file("~/.ssh/llaveTetris.pub")
}

# Creación de la VPC
resource "aws_vpc" "tetris_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Tetris-VPC"
  }
}

# Subnet Pública
resource "aws_subnet" "tetris_public_subnet" {
  vpc_id            = aws_vpc.tetris_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "Tetris-Publica"
  }
}
# Conexión de la Subnet Pública a un Internet Gateway
resource "aws_internet_gateway" "tetris_igw" {
  vpc_id = aws_vpc.tetris_vpc.id

  tags = {
    Name = "Tetris-Internet-Gateway"
  }
}

resource "aws_route" "tetris_public_internet_route" {
  route_table_id         = aws_vpc.tetris_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.tetris_igw.id
}

# Subnet Privada
resource "aws_subnet" "tetris_private_subnet" {
  vpc_id            = aws_vpc.tetris_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "Tetris-Privada"
  }
}
# Security Group para la instancia EC2 en la subnet privada
resource "aws_security_group" "tetris_sg" {
  name        = "tetris-security-group"
  description = "Security group para la instancia Tetris"

  vpc_id = aws_vpc.tetris_vpc.id

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
resource "aws_instance" "tetris_instance" {
  ami           = "ami-0e001c9271cf7f3b9"  # Ubuntu 22.04 AMI, cambia según tu región y AMI
  instance_type = "t2.large"
  subnet_id     = aws_subnet.tetris_private_subnet.id
  key_name      = "llaveTetris"  # Cambia al nombre de tu llave pública en AWS

  security_groups = [aws_security_group.tetris_sg.id]

  tags = {
    Name = "Tetris-Instance"
  }
  user_data     =<<-EOF
        #!/bin/bash
        sudo apt update
        sudo apt install docker-compose -y
        git clone https://github.com/FelipeTM25/tetris.git
        cd tetris/
        sudo docker build -t apptetris:v01 .
        sudo docker run -d -p 3000:3000 apptetris:v01 npm start
        EOF

  # No asociar IP pública, ya que la instancia estará en la subred privada
  associate_public_ip_address = false
}
# Asociar instancia EC2 al Load Balancer clásico
resource "aws_elb" "tetris_elb" {
  name               = "tetris-load-balancer"
  availability_zones = ["us-east-1a", "us-east-1b"]  # Cambia según tus zonas de disponibilidad

  listener {
    instance_port     = 3000
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  instances = [aws_instance.tetris_instance.id]

  tags = {
    Name = "Tetris-Load-Balancer"
}
}