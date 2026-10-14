# Azure DevOps examples

Run each directory independently; they are alternative compositions, not sequential states for the same project.

| Example | Composition |
|---|---|
| [01_project_with_oidc_service_connection](01_project_with_oidc_service_connection/) | Project, Entra app/SP, WIF trust, external FK RBAC |
| [02_project_with_keyvault_variable_group](02_project_with_keyvault_variable_group/) | Same foundation, external FK Key Vault, secret-name variable-group link |

Use different project names if keeping both examples. Existing organization/subscription/resource group, provider bootstrap authentication and sufficient administration rights are prerequisites. Copy only the placeholder terraform.tfvars.example and substitute your own nonsecret identifiers. Supply authentication through environment/CLI/OIDC, never tfvars. Each example pins live-reviewed provider versions and dependency commits. No pipeline definitions, YAML or deployment targets are included.

See the root [README](../README.md) for claims, issuer migration and the complete input/output contract, and [VERIFICATION](../VERIFICATION.md) for static validation output. No plan or apply was executed during module verification.
