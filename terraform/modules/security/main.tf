resource "aws_security_group" "quarantine" {
  name        = "quarantine-sg"
  description = "Denies all traffic for instance isolation."
  vpc_id      = var.vpc_id

  tags = {
    Name = "Quarantine SG"
  }
}

resource "aws_security_group" "normal_access" {
  name        = "normal-access-sg"
  description = "Allows inbound SSH from anywhere."
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Normal Access SG"
  }
}
