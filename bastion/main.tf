##################
### BASTION SG
##################

resource "aws_security_group" "bastion_sg" {
  vpc_id      = var.vpc_id
  name        = "${var.tags["Environment"]}-bastion-sg"
  description = "Security group for the Bastion Host"
  tags = {
    Service = "${var.tags["Environment"]}-bastion-sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "bastion_egress" {
  security_group_id = aws_security_group.bastion_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound traffic from bastion"
}

##################
### LATEST AMAZON LINUX AMI
##################

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Amazon's official account ID for Amazon Linux AMIs

}

##################
### LATEST UBUNTU AMI
##################

# data "aws_ami" "ubuntu" {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }

#   owners = ["099720109477"] # Canonical's official account ID for Ubuntu AMIs
# }

##################
### IAM INSTANCE PROFILE 
##################

resource "aws_iam_role" "instance_role" {
  name = "eks-bastion-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# This policy can be adjusted in the future to be more restrictive and tailored specifically for EKS admin purposes.
resource "aws_iam_role_policy_attachment" "eks_admin_policy" {
  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"

}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "ssm-instance-profile"
  role = aws_iam_role.instance_role.name
}

##################
### BASTION INSTANCE
##################

resource "aws_instance" "bastion" {
  for_each               = toset(var.subnet_ids)
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = each.value # This will loop through each subnet ID
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.instance_profile.name

  key_name = null # This disables SSH key-pair access

  user_data_replace_on_change = true
  # user_data                   = <<-EOF

  # #!/bin/bash

  # # Update the system
  # apt-get -y update
  # apt-get -y upgrade

  # # Install zsh
  # apt-get -y install zsh

  # # Install util-linux to use the 'chsh' command (already included in util-linux in Ubuntu)
  # apt-get -y install util-linux

  # # Install git and wget, needed for Oh My Zsh installation
  # apt-get -y install git wget

  # # Function to install Oh My Zsh for a given user
  # install_oh_my_zsh() {
  #   local user=$1
  #   local user_home=$2

  #   # Clone Oh My Zsh repository
  #   sudo -u $user git clone https://github.com/ohmyzsh/ohmyzsh.git $user_home/.oh-my-zsh

  #   # Copy the zshrc template provided by Oh My Zsh
  #   sudo -u $user cp $user_home/.oh-my-zsh/templates/zshrc.zsh-template $user_home/.zshrc

  #   # Set the ownership of the .zshrc file to the user
  #   chown $user:$user $user_home/.zshrc
  # }

  # # Loop through each user and update their shell and install Oh My Zsh
  # for user in $(awk -F: '{ if ($7 != "/usr/sbin/nologin" && $7 != "/bin/false" && $1 != "root") print $1 }' /etc/passwd); do
  #   user_home=$(eval echo ~$user)

  #   # Change the shell to zsh for each user
  #   chsh -s "$(which zsh)" $user

  #   # Check if the user home directory exists
  #   if [ -d "$user_home" ]; then
  #     # Install Oh My Zsh for this user
  #     install_oh_my_zsh $user $user_home
  #   fi
  # done

  # # Optionally, also change the shell for the root user and install Oh My Zsh
  # chsh -s "$(which zsh)" root
  # root_home=$(eval echo ~root)
  # install_oh_my_zsh root $root_home

  # # Print a message indicating completion
  # echo "Shell for all users has been updated to zsh, and Oh My Zsh installed."

  # # AWS CLI 2 installation
  # apt-get -y remove awscli
  # curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  # unzip awscliv2.zip
  # sudo ./aws/install

  # # KUBECTL and ARGOCD CLI installation
  # KUBECTL_VERSION="v1.28.0"
  # ARGOCD_VERSION="v2.7.4"

  # # Install kubectl
  # curl -LO "https://dl.k8s.io/release/$${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
  # chmod +x kubectl
  # sudo mv kubectl /usr/local/bin/

  # # Install ArgoCD CLI
  # curl -sSL -o argocd "https://github.com/argoproj/argo-cd/releases/download/$${ARGOCD_VERSION}/argocd-linux-amd64"
  # chmod +x argocd
  # sudo mv argocd /usr/local/bin/

  # # For root user
  # echo 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' >> /root/.zshrc

  # # For default Ubuntu user (assuming 'ubuntu' is the default user)
  # echo 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' >> /home/ubuntu/.zshrc
  # chown ubuntu:ubuntu /home/ubuntu/.zshrc

  # # Ensure changes are applied
  # source /root/.zshrc
  # sudo -u ubuntu source /home/ubuntu/.zshrc

  # EOF
  # USER DATA AMAZON LINUX
  user_data = <<-EOF
    #!/bin/bash

    # Update the system
    yum -y update

    # Install zsh
    yum -y install zsh

    # Install util-linux-user to use the 'chsh' command
    yum -y install util-linux-user

    # Install git and wget, needed for Oh My Zsh installation
    yum -y install git wget

    # Function to install Oh My Zsh for a given user
    install_oh_my_zsh() {
      local user=$1
      local user_home=$2

      # Clone Oh My Zsh repository
      sudo -u $user git clone https://github.com/ohmyzsh/ohmyzsh.git $user_home/.oh-my-zsh

      # Copy the zshrc template provided by Oh My Zsh
      sudo -u $user cp $user_home/.oh-my-zsh/templates/zshrc.zsh-template $user_home/.zshrc

      # Set the ownership of the .zshrc file to the user
      chown $user:$user $user_home/.zshrc
    }

    # Loop through each user and update their shell and install Oh My Zsh
    for user in $(awk -F: '{ if ($7 != "/sbin/nologin" && $7 != "/bin/false" && $1 != "root") print $1 }' /etc/passwd); do
    user_home=$(eval echo ~$user)

    # Change the shell to zsh for each user
    chsh -s "$(which zsh)" $user

    # Check if the user home directory exists
    if [ -d "$user_home" ]; then
        # Install Oh My Zsh for this user
        install_oh_my_zsh $user $user_home
    fi
    done

    # Optionally, also change the shell for the root user and install Oh My Zsh
    chsh -s "$(which zsh)" root
    root_home=$(eval echo ~root)
    install_oh_my_zsh root $root_home

    # Print a message indicating completion
    echo "Shell for all users has been updated to zsh, and Oh My Zsh installed."

    # AWS CLI 2 installation
    yum remove awscli
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install

    # KUBECTL and ARGOCD CLI installtion
    KUBECTL_VERSION="v1.28.0"
    ARGOCD_VERSION="v2.7.4"

    # Install kubectl
    curl -LO "https://dl.k8s.io/release/$${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/

    # Install ArgoCD CLI
    curl -sSL -o argocd "https://github.com/argoproj/argo-cd/releases/download/$${ARGOCD_VERSION}/argocd-linux-amd64"
    chmod +x argocd
    sudo mv argocd /usr/local/bin/

    # For root user
    echo 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' >> /root/.zshrc

    # For ec2-user
    echo 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' >> /home/ec2-user/.zshrc
    chown ec2-user:ec2-user /home/ec2-user/.zshrc

    # Ensure changes are applied
    source /root/.zshrc
    sudo -u ec2-user source /home/ec2-user/.zshrc

       EOF

  tags = {
    Name        = var.bastion_name
    Environment = var.tags["Environment"]
    Terraform   = var.tags["Terraform"]
    Purpose     = var.tags["Purpose"]
  }
}
