output "jumpbox_instance_id" {
  description = "EC2 instance ID of the jumpbox"
  value       = aws_instance.jumpbox.id
}

output "jumpbox_private_ip" {
  description = "Private IP of the jumpbox (access via SSM Session Manager)"
  value       = aws_instance.jumpbox.private_ip
}

output "jumpbox_security_group_id" {
  description = "Security group ID of the jumpbox"
  value       = aws_security_group.jumpbox.id
}

output "jumpbox_role_arn" {
  description = "IAM role ARN of the jumpbox"
  value       = aws_iam_role.jumpbox.arn
}
