package test

import (
	"fmt"
	"testing"

	"github.com/aws/aws-sdk-go/service/sts"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Function to construct the ARN for the "GitHubEstaRole" dynamically
func generateAllowedRoleArn(t *testing.T, awsRegion string, roleName string) string {
	// Create an STS client
	stsClient, err := aws.NewStsClientE(t, awsRegion)
	if err != nil {
		t.Fatalf("Failed to create STS client: %v", err)
	}

	// Get the caller identity, which includes the AWS account ID
	callerIdentity, err := stsClient.GetCallerIdentity(&sts.GetCallerIdentityInput{})
	if err != nil {
		t.Fatalf("Failed to get caller identity: %v", err)
	}

	// Construct the ARN using the account ID and the provided role name
	accountID := *callerIdentity.Account
	roleArn := fmt.Sprintf("arn:aws:iam::%s:role/%s", accountID, roleName)

	return roleArn
}

func TestSecretsModule(t *testing.T) {
	t.Parallel()

	awsRegion := "us-east-1"

	roleName := "GitHubEstaRole"

	// Generate the allowed role ARN
	allowedRoleArn := generateAllowedRoleArn(t, awsRegion, roleName)

	// Configure Terraform options for the secrets module
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"allowed_roles": []string{allowedRoleArn},
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
