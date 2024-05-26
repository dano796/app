provider "aws" {
  region = "us-east-1"  # Cambia la región si es necesario
}

resource "aws_vpc" "snake_game" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "snake-game"
  }
}

resource "aws_subnet" "snake_publica" {
  vpc_id     = aws_vpc.snake_game.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"  # Cambia la zona si es necesario
  tags = {
    Name = "snake-publica"
  }
}

resource "aws_subnet" "snake_privada" {
  vpc_id     = aws_vpc.snake_game.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1a"  # Cambia la zona si es necesario
  tags = {
    Name = "snake-privada"
  }
}

resource "aws_security_group" "snake_sg" {
  vpc_id = aws_vpc.snake_game.id
  tags = {
    Name = "snake-sg"
  }

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

resource "aws_instance" "snake_instance" {
  ami           = "ami-0bb84b8ffd87024d8"  # Ubuntu 22.04 AMI, cambia según la región
  instance_type = "t2.large"
  subnet_id     = aws_subnet.snake_privada.id
  key_name      = "llavesnake"

  security_groups = [aws_security_group.snake_sg.name]

  tags = {
    Name = "snake-instance"
  }
}

resource "aws_elb" "snake_elb" {
  name               = "snake-elb"
  availability_zones = ["us-east-1a"]  # Cambia la zona si es necesario
  security_groups    = [aws_security_group.snake_sg.id]
  subnets            = [aws_subnet.snake_publica.id]

  listener {
    instance_port     = 3000
    instance_protocol = "HTTP"
    lb_port           = 3000
    lb_protocol       = "HTTP"
  }

  health_check {
    target              = "HTTP:3000/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  instances = [aws_instance.snake_instance.id]

  tags = {
    Name = "snake-elb"
  }
}
