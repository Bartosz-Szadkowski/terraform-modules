package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestVpcModule(t *testing.T) {
	t.Parallel()

	// Configure the Terraform options
	terraformOptions := &terraform.Options{
		TerraformDir: "../", // Assumes the test is inside a "tests" directory
		Vars: map[string]interface{}{
			"vpc_cidr_block":                  "10.0.0.0/16",
			"public_subnets_cidr_blocks":      []string{"10.0.1.0/24", "10.0.2.0/24"},
			"private_subnets_eks_cidr_blocks": []string{"10.0.3.0/24", "10.0.4.0/24"},
			"private_subnets_rds_cidr_blocks": []string{"10.0.5.0/24", "10.0.6.0/24"},
			"availability_zones":              []string{"us-east-1a", "us-east-1b"},
			"tags": map[string]string{
				"Environment": "dev",
				"Terraform":   "true",
			},
		},
	}

	// Ensure resources are destroyed after test completion
	defer terraform.Destroy(t, terraformOptions)

	// Run `terraform init` and `terraform apply`
	terraform.InitAndApply(t, terraformOptions)

	// Validate VPC ID output
	vpcID := terraform.Output(t, terraformOptions, "vpc_id")
	assert.NotEmpty(t, vpcID, "VPC ID should not be empty")

	// Validate public subnet IDs
	publicSubnetIDs := terraform.OutputList(t, terraformOptions, "public_subnet_ids")
	assert.Equal(t, 2, len(publicSubnetIDs), "There should be exactly 2 public subnets")
	for _, subnetID := range publicSubnetIDs {
		assert.NotEmpty(t, subnetID, "Public subnet ID should not be empty")
	}

	// Validate private EKS subnet IDs
	privateEksSubnetIDs := terraform.OutputList(t, terraformOptions, "private_eks_subnet_ids")
	assert.Equal(t, 2, len(privateEksSubnetIDs), "There should be exactly 2 private EKS subnets")
	for _, subnetID := range privateEksSubnetIDs {
		assert.NotEmpty(t, subnetID, "Private EKS subnet ID should not be empty")
	}

	// Validate private RDS subnet IDs
	privateRdsSubnetIDs := terraform.OutputList(t, terraformOptions, "private_rds_subnet_ids")
	assert.Equal(t, 2, len(privateRdsSubnetIDs), "There should be exactly 2 private RDS subnets")
	for _, subnetID := range privateRdsSubnetIDs {
		assert.NotEmpty(t, subnetID, "Private RDS subnet ID should not be empty")
	}

	// Validate CIDR block of VPC
	vpcCidrBlock := terraform.Output(t, terraformOptions, "vpc_cidr_block")
	assert.Equal(t, "10.0.0.0/16", vpcCidrBlock, "VPC CIDR block should match the specified value")
}
