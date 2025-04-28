variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  default = "10.0.2.0/24"
}

variable "instance_type" {
  default = "t3.small"
}

variable "ami_id" {
  default = "ami-084568db4383264d4"
}

variable "key_name" {
  description = "Name of the existing EC2 Key Pair"
}

variable "server_jar_url" {
  default = "https://piston-data.mojang.com/v1/objects/e6ec2f64e6080b9b5d9b471b291c33cc7f509733/server.jar"
}

variable "lobby_port" {
  default = 25565
}

variable "survival_port" {
  default = 25566
}
