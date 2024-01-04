terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

#resource "aws_key_pair" "deployer" {
#  key_name   = "Rahul-lab"

provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_security_group" "SG-MT" {
  name        = "SG-MT"
  description = "Allow TLS inbound traffic"
  
  

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [ "0.0.0.0/0" ]
  }
  ingress {
    description      = "Custom-SSH"
    from_port        = 64567
    to_port          = 64567
    protocol         = "tcp"
    cidr_blocks      = [ "0.0.0.0/0" ]
  
  }
  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [ "0.0.0.0/0" ]
  
  }
  
  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [ "0.0.0.0/0" ]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

resource "tls_private_key" "tlskey" {
    algorithm = "RSA"  
    rsa_bits = 4096
  
}


resource "aws_key_pair" "MT-ssh_key" {

  key_name   = "MT-ssh_key"  
  public_key = tls_private_key.tlskey.public_key_openssh
  provisioner "local-exec" {

    command = "echo '${tls_private_key.tlskey.private_key_openssh}' > ./MT-ssh_key ; chmod 400 ./MT-ssh_key"

  }

  provisioner "local-exec" {

    when    = destroy

    command = "rm -rf ./MT-ssh_key"

  }


  tags = {

    Name = "MT-ssh_key"

  }

}

resource "aws_instance" "app_server" {
  ami           = "ami-04f5097681773b989"
  instance_type = "t2.micro"
  key_name      =  aws_key_pair.MT-ssh_key.key_name
  vpc_security_group_ids = [ aws_security_group.SG-MT.id ]
  root_block_device {
    volume_size = 20 
    volume_type = "gp3"
    encrypted = false
    #kms_key_id = "arn"
    delete_on_termination = true
  
  }
    tags = {
    Name = "MT-Sever"
  }
}
