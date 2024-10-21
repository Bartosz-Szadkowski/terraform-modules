##################
### EKS CLUSTER
##################

resource "aws_eks_cluster" "this" {
  name     = "${var.tags["Environment"]}-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
    security_group_ids      = [aws_security_group.eks_cluster_sg.id]
  }

  version    = var.cluster_version
  depends_on = [aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy]

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  tags = {
    Name = "${var.tags["Environment"]}-eks-cluster"
  }
}

resource "aws_security_group" "eks_cluster_sg" {
  vpc_id      = var.vpc_id
  description = "Security group for the EKS Cluster"
  tags = {
    Name = "${var.tags["Environment"]}-eks-cluster-sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "eks_cluster_egress" {
  security_group_id = aws_security_group.eks_cluster_sg.id
  cidr_ipv4         = var.vpc_cidr_block
  ip_protocol       = "-1"
  description       = "Allow all traffic from eks cluster in vpc"
}

resource "aws_vpc_security_group_ingress_rule" "eks_cluster_ingress" {
  security_group_id = aws_security_group.eks_cluster_sg.id
  cidr_ipv4         = var.vpc_cidr_block
  from_port         = "443"
  to_port           = "443"
  ip_protocol       = "tcp"
  description       = "Allow traffic from eks worker nodes in vpc"
}

resource "aws_eks_addon" "eks_pod_identity_agent" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "eks-pod-identity-agent"
}

##################
### EKS WORKER NODES
##################

# Fetch the latest optimised AMI for EKS
data "aws_ssm_parameter" "eks_ami_release_version" {
  name = "/aws/service/eks/optimized-ami/${aws_eks_cluster.this.version}/amazon-linux-2/recommended/release_version"
}

resource "aws_eks_node_group" "eks_worker_nodes_group" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.tags["Environment"]}-eks-worker-nodes"
  node_role_arn   = aws_iam_role.eks_worker_node_role.arn
  release_version = nonsensitive(data.aws_ssm_parameter.eks_ami_release_version.value)
  subnet_ids      = var.subnet_ids
  capacity_type   = "ON_DEMAND"
  instance_types  = [var.instance_type]

  scaling_config {
    desired_size = var.desired_capacity
    max_size     = var.max_size
    min_size     = var.min_size
  }

  update_config {
    max_unavailable = 1
  }
}


