output "lobby_server_public_ip" {
  value = aws_instance.lobby_server.public_ip
}

output "survival_server_public_ip" {
  value = aws_instance.survival_server.public_ip
}

output "nlb_dns_name" {
  value = aws_lb.nlb.dns_name
  description = "To connect to the server use DNS name:25565/25566"
}
