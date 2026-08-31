output "jenkins_public_ip" {
  description = "Public IP of the Jenkins EC2 instance"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_public_dns" {
  description = "Public DNS of the Jenkins EC2 instance"
  value       = aws_instance.jenkins.public_dns
}

output "jenkins_role_arn" {
  value = aws_iam_role.jenkins.arn
}

output "jenkins_ssh_public_key" {
  description = "SSH public key for Jenkins EC2 access"
  value       = aws_key_pair.jenkins.fingerprint
}
