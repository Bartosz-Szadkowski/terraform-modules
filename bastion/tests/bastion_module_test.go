package test

import (
	"fmt"
	"testing"
	"time"

	"github.com/google/uuid" // For generating a unique identifier
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestBastionModule(t *testing.T) {
	t.Parallel()

	awsRegion := "us-east-1"
	environment := "test"

	// Generate a unique identifier for this test run
	uniqueID := uuid.New().String()
	bastionName := fmt.Sprintf("%s-bastion-instance-%s", environment, uniqueID)

	// Step 1: Set up Terraform options for the VPC module with retryable errors
	vpcTerraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../vpc",
		Vars: map[string]interface{}{
			"vpc_cidr_block":                  "10.0.0.0/16",
			"public_subnets_cidr_blocks":      []string{"10.0.1.0/24", "10.0.2.0/24"},
			"private_subnets_eks_cidr_blocks": []string{"10.0.3.0/24", "10.0.4.0/24"},
			"private_subnets_rds_cidr_blocks": []string{"10.0.5.0/24", "10.0.6.0/24"},
			"availability_zones":              []string{"us-east-1a", "us-east-1b"},
			"tags": map[string]string{
				"Environment": environment,
				"Terraform":   "true",
			},
		},
	})

	defer terraform.Destroy(t, vpcTerraformOptions)
	terraform.InitAndApply(t, vpcTerraformOptions)

	vpcID := terraform.Output(t, vpcTerraformOptions, "vpc_id")
	publicSubnetIDs := terraform.OutputList(t, vpcTerraformOptions, "public_subnet_ids")

	// Step 2: Set up Terraform options for the bastion module with retryable errors
	bastionTerraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"vpc_id":        vpcID,
			"subnet_ids":    publicSubnetIDs,
			"instance_type": "t2.micro",
			"bastion_name":  bastionName, // Pass the unique name here as a variable
			"tags": map[string]string{
				"Environment": environment,
				"Terraform":   "true",
				"Purpose":     "bastion",
			},
		},
	})

	defer terraform.Destroy(t, bastionTerraformOptions)
	terraform.InitAndApply(t, bastionTerraformOptions)

	bastionSGID := terraform.Output(t, bastionTerraformOptions, "bastion_security_group_id")
	assert.NotEmpty(t, bastionSGID, "Bastion security group ID should not be empty")

	instanceRoleARN := terraform.Output(t, bastionTerraformOptions, "instance_role_arn")
	assert.NotEmpty(t, instanceRoleARN, "Bastion instance role ARN should not be empty")

	// Retrieve all bastion instances by tag using Terratest helper function
	instanceIDs := aws.GetEc2InstanceIdsByTag(t, awsRegion, "Name", bastionName)

	assert.Equal(t, len(publicSubnetIDs), len(instanceIDs), "The number of bastion instances should match the number of subnets")

	maxWait := 5 * time.Minute

	for _, instanceID := range instanceIDs {
		assert.NotEmpty(t, instanceID, "Bastion instance ID should not be empty")
		aws.WaitForSsmInstance(t, awsRegion, instanceID, maxWait)
	}
}
