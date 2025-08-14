data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "local_file" "ssh_private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${var.key_name}.pem"
  file_permission = "0400"
}

resource "aws_instance" "public_instance" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  subnet_id              = var.public_subnet_id
  key_name               = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = [var.access_sg_id]

  tags = {
    Name = "Public Test Instance"
  }
}

resource "aws_instance" "private_instance" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  subnet_id              = var.private_subnet_id
  key_name               = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = [var.access_sg_id]

  tags = {
    Name = "Private Test Instance (Target)"
  }
}