output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = aws_subnet.public.*.id
}

output "private_eks_subnet_ids" {
  description = "The IDs of the private subnets"
  value       = aws_subnet.private_eks.*.id
}

output "private_rds_subnet_ids" {
  description = "The IDs of the rds private subnets"
  value       = aws_subnet.private_rds.*.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}
