package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestSecretsModule(t *testing.T) {
	t.Parallel()

	awsRegion := "us-east-1"

	// Get the ARN of the current IAM user
	currentUserArn := aws.GetIamCurrentUserArn(t)
	fmt.Printf("Using IAM user ARN: %s\n", currentUserArn)

	// Configure Terraform options for the secrets module
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"allowed_roles": []string{currentUserArn},
		},
	})

	// Ensure the resources are cleaned up after the test
	defer terraform.Destroy(t, terraformOptions)

	// Run Terraform init and apply
	terraform.InitAndApply(t, terraformOptions)

	// Retrieve outputs and validate them
	secretID := terraform.Output(t, terraformOptions, "argocd_secret_id")
	assert.NotEmpty(t, secretID, "The Secret ID should not be empty")

	// Retrieve the secret value from AWS Secrets Manager
	secretValue := aws.GetSecretValue(t, awsRegion, secretID)
	assert.NotEmpty(t, secretValue, "The Secret value should not be empty")

	// Validate the secret value length (should be 16 as defined in the module)
	assert.Equal(t, 16, len(secretValue), "The secret value should be 16 characters long")
}
