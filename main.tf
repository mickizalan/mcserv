provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "minecraft-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidr
  map_public_ip_on_launch = true

  availability_zone = "us-east-1a"
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidr

  availability_zone = "us-east-1b"
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "minecraft_sg" {
  name        = "minecraft-sg"
  description = "Allow SSH and Minecraft ports"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = var.lobby_port
    to_port     = var.lobby_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = var.survival_port
    to_port     = var.survival_port
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

resource "aws_lb" "nlb" {
  name               = "minecraft-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.public_subnet.id]

  enable_cross_zone_load_balancing = true
}

resource "aws_lb_target_group" "lobby_tg" {
  name        = "lobby-tg"
  port        = var.lobby_port
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"
}

resource "aws_lb_target_group" "survival_tg" {
  name        = "survival-tg"
  port        = var.survival_port
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"
}

resource "aws_lb_listener" "lobby_listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = var.lobby_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lobby_tg.arn
  }
}

resource "aws_lb_listener" "survival_listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = var.survival_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.survival_tg.arn
  }
}

resource "aws_instance" "lobby_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.minecraft_sg.id]
  associate_public_ip_address = true
  key_name               = var.key_name

  tags = {
    Name = "Lobby-Server"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo su
              apt update
              apt upgrade -y
              apt install -y openjdk-21-jre-headless
              mkdir /home/ubuntu/minecraft
              cd /home/ubuntu/minecraft
              wget ${var.server_jar_url} -O server.jar
              java -Xmx1024M -Xms1024M -jar server.jar nogui
              echo "eula=true" > eula.txt
              echo -e "gamemode=creative\nonline-mode=false" > server.properties
              nohup java -Xmx1024M -Xms1024M -jar server.jar nogui &
              EOF
}

resource "aws_instance" "survival_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.minecraft_sg.id]
  associate_public_ip_address = true
  key_name               = var.key_name

  tags = {
    Name = "Survival-Server"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo su
              apt update
              apt upgrade -y
              apt install -y openjdk-21-jre-headless
              mkdir /home/ubuntu/minecraft
              cd /home/ubuntu/minecraft
              wget ${var.server_jar_url} -O server.jar
              java -Xmx1024M -Xms1024M -jar server.jar nogui
              echo "eula=true" > eula.txt
              echo -e "server-port=25566\nonline-mode=false" > server.properties
              rm -rf /home/ubuntu/minecraft/world/session.lock
              nohup java -Xmx1024M -Xms1024M -jar server.jar nogui &
              EOF
}

resource "aws_lb_target_group_attachment" "lobby_attachment" {
  target_group_arn = aws_lb_target_group.lobby_tg.arn
  target_id        = aws_instance.lobby_server.id
  port             = var.lobby_port
}

resource "aws_lb_target_group_attachment" "survival_attachment" {
  target_group_arn = aws_lb_target_group.survival_tg.arn
  target_id        = aws_instance.survival_server.id
  port             = var.survival_port
}
