resource "aws_vpc" "clc_vpc" {
  cidr_block       = "172.16.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "vpc-terraform_tf_teste2"
  }
}

resource "aws_subnet" "public_subnet_1a" {
  vpc_id     = aws_vpc.clc_vpc.id
  cidr_block = "172.16.1.0/24"
  availability_zone = "us-east-1a" 
  tags = {
    Name = "public_subnet_1a_tf"
  }
}

resource "aws_subnet" "private_subnet_1a" {
  vpc_id     = aws_vpc.clc_vpc.id
  cidr_block = "172.16.10.0/24"
  availability_zone = "us-east-1a" 
  tags = {
    Name = "private_subnet_1a_tf"
  }
}

## Cria Internet Gateway com a referencia da vpc clc_vpc
resource "aws_internet_gateway" "gw_clc_vpc" {
  vpc_id = aws_vpc.clc_vpc.id

  tags = {
    Name = "igw_clc_vpc_tf"
  }
}

## Cria tabela de rota publica com rota para o Internet Gateway
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.clc_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw_clc_vpc.id
  }

  tags = {
    Name = "public_rt_t"
  }
}

## Associa a tabela de rota publica na subnet publica 1a ##
resource "aws_route_table_association" "rt_pub_association_subnet_1a" {
  subnet_id      = aws_subnet.public_subnet_1a.id
  route_table_id = aws_route_table.public_rt.id
}


## Cria um IP público para nat gateway 1a ##
resource "aws_eip" "eip_nat_gw_1a" {
  domain   = "vpc"
}

## Cria o nat gateway da zona de disponibilidade 1A ## 
resource "aws_nat_gateway" "nat_gw_1a" {
  allocation_id = aws_eip.eip_nat_gw_1a.id
  subnet_id     = aws_subnet.public_subnet_1a.id

  tags = {
    Name = "nat_gw_1a_tf"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw_clc_vpc]
}




## Cria tabela de rota privada 1A com rota para o NAT Gateway da 1A
resource "aws_route_table" "private_rt_1a" {
  vpc_id = aws_vpc.clc_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_1a.id
  }

  tags = {
    Name = "private_rt_1a_tf"
  }
}

## Associa a tabela de rota privada 1a na subnet privada 1a ##
resource "aws_route_table_association" "rt_priv_association_subnet_1a" {
  subnet_id      = aws_subnet.private_subnet_1a.id
  route_table_id = aws_route_table.private_rt_1a.id
}

## Cria subnet pública na zona 1c
resource "aws_subnet" "public_subnet_1c" {
  vpc_id            = aws_vpc.clc_vpc.id
  cidr_block        = "172.16.2.0/24"
  availability_zone = "us-east-1c" 
  tags = {
    Name = "public_subnet_1c_tf"
  }
}

## Cria subnet privada na zona 1c
resource "aws_subnet" "private_subnet_1c" {
  vpc_id            = aws_vpc.clc_vpc.id
  cidr_block        = "172.16.20.0/24"
  availability_zone = "us-east-1c" 
  tags = {
    Name = "private_subnet_1c_tf"
  }
}


## Associa a tabela de rota pública na subnet pública 1c
resource "aws_route_table_association" "rt_pub_association_subnet_1c" {
  subnet_id      = aws_subnet.public_subnet_1c.id
  route_table_id = aws_route_table.public_rt.id
}

## Cria um IP público para o NAT Gateway 1c
resource "aws_eip" "eip_nat_gw_1c" {
  domain = "vpc"
}


## Cria o NAT Gateway da zona de disponibilidade 1c
resource "aws_nat_gateway" "nat_gw_1c" {
  allocation_id = aws_eip.eip_nat_gw_1c.id
  subnet_id     = aws_subnet.public_subnet_1c.id

  tags = {
    Name = "nat_gw_1c_tf"
  }

  depends_on = [aws_internet_gateway.gw_clc_vpc]
}



## Cria tabela de rota privada 1c com rota para o NAT Gateway da 1c
resource "aws_route_table" "private_rt_1c" {
  vpc_id = aws_vpc.clc_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_1c.id
  }

  tags = {
    Name = "private_rt_1c_tf"
  }
}


## Associa a tabela de rota privada 1c na subnet privada 1c
resource "aws_route_table_association" "rt_priv_association_subnet_1c" {
  subnet_id      = aws_subnet.private_subnet_1c.id
  route_table_id = aws_route_table.private_rt_1c.id
}


resource "aws_security_group" "sg_web_pub" {
  name        = "sg_web_pub_tf"
  description = "Permite acesso HTTP na porta 80"
  vpc_id      = aws_vpc.clc_vpc.id

  ingress {
    description = "HTTP Publico"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Todo o trafego de saida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_web_pub_tf"
  }
}


resource "aws_instance" "ec2_publica_apache" {
  ami                         = "ami-0c7217cdde317cfec" # Amazon Linux 2023 (ou AMI compatível com sua região us-east-1)
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet_1a.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg_web_pub.id]

  # Script executado no primeiro boot para instalar o Apache e criar a pagina
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y httpd
              systemctl start httpd
              systemctl enable httpd
              
              # Criando a pagina index.html com o texto solicitado
              echo "Insira aqui o texto da sua pagina index.html" > /var/www/html/index.html
              EOF

  tags = {
    Name = "ec2_publica_apache_tf"
  }
}

output "public_ip_apache" {
  description = "IP publico da instancia EC2 com Apache"
  value       = aws_instance.ec2_publica_apache.public_ip
}
