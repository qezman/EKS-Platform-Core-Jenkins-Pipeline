resource "aws_security_group" "jenkins" {
  name        = "${var.project}-${var.environment}-jenkins-sg"
  description = "Security group for the jenkins server"
  vpc_id      = var.vpc_id

  #   Allow SSH access
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

  # installs Jenkins, Java, Docker, and kubectl

  user_data = <<-EOF
  #!/bin/bash
  set -e

  # Update system
  apt-get update -y
  apt-get upgrade -y

  # Java (required by Jenkins)
  apt-get install -y fontconfig openjdk-17-jre  

  # Jenkins
  curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee \
    /usr/share/keyrings/jenkins-keyring.asc > /dev/null
  echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
    "https://pkg.jenkins.io/debian-stable binary/" | tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null
  apt-get update -y
  apt-get install -y jenkins
  systemctl enable jenkins
  systemctl start jenkins

  # Docker
  apt-get install -y ca-certificates curl gnupg
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io
  systemctl enable docker
  systemctl start docker
  usermod -aG docker jenkins

  # Terraform
  wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    tee /etc/apt/sources.list.d/hashicorp.list
  apt-get update -y
  apt-get install -y terraform

  # kubectl
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

  # Helm
  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  chmod 700 get_helm.sh
  ./get_helm.sh

  # AWS CLI v2
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  apt-get install -y unzip
  unzip awscliv2.zip
  ./aws/install

  systemctl restart jenkins

  EOF

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name        = "${var.project}-${var.environment}-jenkins"
    Environment = var.environment
  }
}

resource "aws_iam_policy" "terraform_deployer" {
  name   = "${var.project}-${var.environment}-terraform-deployer-policy"
  policy = data.aws_iam_policy_document.terraform_deployer.json
}

resource "aws_iam_role" "jenkins" {
  name = "${var.project}-${var.environment}-jenkins-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = {
    Name        = "${var.project}-${var.environment}-jenkins-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "jenkins_deployer_policy" {
  role       = aws_iam_role.jenkins.name
  policy_arn = aws_iam_policy.terraform_deployer.arn
}

resource "aws_iam_instance_profile" "jenkins" {
  name = "${var.project}-${var.environment}-jenkins-profile"
  role = aws_iam_role.jenkins.name
}
