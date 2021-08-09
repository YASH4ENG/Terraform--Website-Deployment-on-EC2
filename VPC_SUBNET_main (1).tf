
provider "aws"{
    region = var.region
    access_key =var.access_key
    secret_key =var.secret_key
}


resource "aws_vpc" "Motivalogic_VPC" {
    cidr_block = "10.0.0.0/16"
    tags={
        Name = "Motivalogic_VPC"
        }
}

resource "aws_subnet" "Motivalogic_Public_SN" {
    vpc_id = aws_vpc.Motivalogic_VPC.id
    cidr_block = "10.0.1.0/24"
    tags={
        Name = "Motivalogic_Public_SN"
        }
}

resource "aws_internet_gateway" "Motivalogic_IGW" {
    vpc_id= aws_vpc.Motivalogic_VPC.id
    tags={
        Name = "Motivalogic_IGW"
        }
}

resource "aws_route_table" "Motivalogic_RT" {
    vpc_id = aws_vpc.Motivalogic_VPC.id

    route{
        cidr_block ="0.0.0.0/0"
        gateway_id = aws_internet_gateway.Motivalogic_IGW.id
    }

    tags={
        Name = "Motivalogic_RT"
        }
}

resource "aws_route_table_association" "Motivalogic_RT_assoc" {
  subnet_id      = aws_subnet.Motivalogic_Public_SN.id
  route_table_id = aws_route_table.Motivalogic_RT.id
  
}            

resource "aws_security_group" "Motivalogic_Frontend_sg" {
    name = "Motivalogic_Frontend_sg"
    description = "Allow inbound traffic"
    vpc_id = aws_vpc.Motivalogic_VPC.id

ingress {
    description      = "Allow inbound traffic from HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    }  
ingress {
    description      = "Allow inbound traffic from HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]   
    }

ingress {
    description      = "Allow inbound traffic from ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]   
  }

egress {
    description      = "All"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]   
  }
  tags = {
      Name = "Motivalogic_Frontend_sg"
  }
}

resource "aws_key_pair" "VPC_key" {
  key_name   = "VPC_key"
  public_key = file("~/c/Users/yashaswi/Desktop/SK.pem")
}

resource "aws_instance" "WP_Server_01" {
    key_name = aws_key_pair.VPC_key.key_name
    subnet_id = aws_subnet.Motivalogic_Public_SN.id
    ami = "ami-0f89681a05a3a9de7"
    instance_type = "t2.micro"
    vpc_security_group_ids = ["${aws_security_group.Motivalogic_Frontend_sg.id}"]
    associate_public_ip_address = true

connection {
    type = "ssh"
    user = "ec2-user"
    private_key = file("~/Documents/DevOps/Terraform/VPC_Lab/id_rsa")
    host = self.public_ip
} 
provisioner "file" {
    source      = "~/Desktop/Resume_Website"
    destination = "/tmp"
  }
  
user_data = <<-EOF
#!/bin/bash
    sudo yum install httpd* -y
    sudo systemctl start httpd
    sudo systemctl enable httpd
    sudo cp -R /tmp/Resume_Website/* /var/www/html
    sudo systemctl restart httpd
    EOF

tags = {
      Name="WP_Server_01"
    }
}

resource "aws_eip" "Motivalogic_IP" {
  instance = aws_instance.WP_Server_01.id
  vpc      = true
}

output "WP_Server_01_Public_IPaddress" {
  value       = aws_eip.Motivalogic_IP
  description = "The Public IP address of the website is : "
}