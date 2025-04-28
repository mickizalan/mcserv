key_name = "mm"  # Change this to you key

vpc_cidr            = "10.0.0.0/16"
public_subnet_cidr  = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"
instance_type       = "t3.small"
ami_id              = "ami-084568db4383264d4"

lobby_port    = 25565
survival_port = 25566

server_jar_url = "https://piston-data.mojang.com/v1/objects/e6ec2f64e6080b9b5d9b471b291c33cc7f509733/server.jar"
