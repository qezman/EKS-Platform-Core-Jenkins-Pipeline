resource "aws_security_group" "jenkins" {
  name        = "${var.project}-${var.environment}-jenkins-sg"
  description = "Security group for the jenkins server"
  vpc_id      = var.vpc_id

  # Allow SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr] // admin's ip
  }

  # Allow access to Jenkins web UI on port 8080
  ingress {
    description = "Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr] // admin's ip
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-${var.environment}-jenkins-sg"
    Environment = var.environment
  }
}

resource "aws_key_pair" "jenkins" {
  key_name   = "${var.project}-${var.environment}-jenkins-key"
  public_key = var.jenkins_ssh_public_key

  tags = {
    Name        = "${var.project}-jenkins-key"
    Environment = var.environment
  }
}

# Jenkins EC2 instance
resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  key_name               = aws_key_pair.jenkins.key_name
  iam_instance_profile   = aws_iam_instance_profile.jenkins.name

  user_data                   = file("${path.module}/templates/install.sh")
  user_data_replace_on_change = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name        = "${var.project}-${var.environment}-jenkins"
    Environment = var.environment
  }
}
