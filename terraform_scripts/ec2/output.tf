output "EC2-Public-IP" {
  value = aws_instance.EC2.public_ip
}