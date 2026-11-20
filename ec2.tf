# resource "aws_instance" "ec2_publica_apache" {
#   ami                         = "ami-0c7217cdde317cfec" # Amazon Linux 2023 (ou AMI compatível com sua região us-east-1)
#   instance_type               = "t2.micro"
#   subnet_id                   = aws_subnet.public_subnet_1a.id
#   associate_public_ip_address = true
#   vpc_security_group_ids      = [aws_security_group.sg_web_pub.id]

#   # Script executado no primeiro boot para instalar o Apache e criar a pagina
#   user_data = <<-EOF
#               #!/bin/bash
#               dnf update -y
#               dnf install -y httpd
#               systemctl start httpd
#               systemctl enable httpd
              
#               # Criando a pagina index.html com o texto solicitado
#               echo "Insira aqui o texto da sua pagina index.html" > /var/www/html/index.html
#               EOF

#   tags = {
#     Name = "ec2_publica_apache_tf"
#   }
# }

# output "public_ip_apache" {
#   description = "IP publico da instancia EC2 com Apache"
#   value       = aws_instance.ec2_publica_apache.public_ip
# }