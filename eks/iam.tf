##################
### EKS CLUSTER ROLE
##################

resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.tags["Environment"]}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSServicePolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

##################
### EKS WORKER NODES ROLE
##################

resource "aws_iam_role" "eks_worker_node_role" {
  name = "${var.tags["Environment"]}-eks-worker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "worker_nodes_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_worker_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "worker_nodes_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_worker_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "worker_nodes_AmazonEKSCNIPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_worker_node_role.name
}

##################
### K8 CLUSTER ACCESS FOR ADMINS
##################

# EKS admins access -> This should be more restrictive, with a dedicated IAM role.
resource "aws_eks_access_entry" "admin_access_entry" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.admin_iam_role
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin_access_policy_association" {
  cluster_name  = aws_eks_cluster.this.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = var.admin_iam_role
  access_scope {
    type = "cluster"
  }
}

# Master admin access
resource "aws_eks_access_entry" "master_admin_access_entry" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.master_admin_iam_arn
  type          = "STANDARD"
}
resource "aws_eks_access_policy_association" "master_admin_access_policy_association" {
  cluster_name  = aws_eks_cluster.this.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = var.master_admin_iam_arn
  access_scope {
    type = "cluster"
  }
}

# GitHub Actions workflow access
resource "aws_eks_access_entry" "github_actions_access_entry" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.github_actions_role
  type          = "STANDARD"
}
resource "aws_eks_access_policy_association" "github_actions_access_policy_association" {
  cluster_name  = aws_eks_cluster.this.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = var.github_actions_role
  access_scope {
    type = "cluster"
  }
}

##################
### IDENTITY ASSOCIATION FOR WORKLOADS
##################

resource "aws_eks_pod_identity_association" "python_web_app_pod_identity_association" {
  cluster_name    = aws_eks_cluster.this.name
  namespace       = var.python_web_app_namespace
  service_account = var.python_web_app_sa
  role_arn        = var.python_web_app_role_arn
}