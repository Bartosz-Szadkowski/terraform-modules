package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestMyModule(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../bastion", // path to your module

		// You can pass variables as needed
		Vars: map[string]interface{}{
			"region": "us-east-1",
		},
	}

	// Ensure that Terraform destroy is run after the test
	defer terraform.Destroy(t, terraformOptions)

	// Run `terraform init` and `terraform apply`
	terraform.InitAndApply(t, terraformOptions)

	// Example output assertion
	output := terraform.Output(t, terraformOptions, "example_output")
	assert.Equal(t, "expected_value", output)
}
