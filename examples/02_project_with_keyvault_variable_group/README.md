# 02 — Project with Key Vault variable group

Adds `terraform-az-fk-key-vault` to the project/WIF/RBAC composition. The vault uses public endpoint access and explicit Get/List secret access policies for the service principal, keeping vault authorization on the vault creation dependency path. No role-assignment logic is duplicated. `rbac.tf` still composes the dedicated FK RBAC module for target scope access.

The vault module receives the service principal output; the DevOps variable group receives the vault name output. Dependencies are resource-level: project/app/SP/endpoint/trust → vault with access policy → variable group. Do not add module-wide depends_on between these two modules, which would introduce a cycle.

## Two-stage configuration

The AzureDevOps provider checks that linked enabled secrets exist while creating the variable group. A new empty vault cannot immediately satisfy that check. This example therefore defaults `link_variable_group = false`:

1. Provision with the link disabled to create the project, trust, RBAC and vault. The default `secret_names = []` contains no fictitious secrets.
2. Have an authorized operator populate the vault through an external secret-management process. The example grants the pipeline identity only Get/List; the bootstrap operator needs separate secret-write permissions. Never put secret values in Terraform or tfvars.
3. Set `secret_names` to the existing enabled secret names and `link_variable_group = true`, then reconcile the configuration. A nonempty set is required. Azure DevOps must be able to reach the public vault endpoint; do not assume a hosted agent's network path is the Library service's path.
4. Authorize the intended pipeline to use the group and connection. `allow_access` remains false. Future value rotations are resolved by Azure Pipelines at runtime; adding/removing names requires updating the set.

Example nonsecret second-stage settings:

```hcl
link_variable_group = true
secret_names        = ["existing-application-secret"]
```

Key Vault-linked variable groups are supported by provider 1.16.0. Only secret names are mapped; no values, certificates or keys are managed. The provider's search_depth defaults to 20; the root contract permits increasing it when the required secret metadata is not found within that search depth. Vault/Entra permission propagation may require waiting before the second stage.


Prerequisites: an existing Azure DevOps organization; Azure subscription and resource group; Entra application-management rights; Azure DevOps project/endpoint/library administration; and permission to grant Azure roles. Configure AzureAD/AzureRM bootstrap authentication externally (for example an existing Azure CLI session), and AzureDevOps authentication using supported environment/OIDC options. Provider credentials are not the pipeline service connection credentials.

Copy `terraform.tfvars.example` to ignored `terraform.tfvars` and replace the placeholder identifiers. The example defaults to Reader on `rbac_scope`; this proves read access without granting deployment privileges. Scope must belong to the supplied subscription. Select a narrowly scoped deployment role if your later pipeline needs writes.

Static checks, which do not contact your subscription or organization:

```bash
tofu fmt -check
tofu init
tofu validate
```

An operator can provision this example with `tofu apply` after reviewing their configuration and costs. No plan/apply was executed during this task. The output service connection ID waits for federated trust and the external FK RBAC module; directory/RBAC propagation can still take time. Authorize only the intended pipeline to use this service connection.

To demonstrate runtime passwordless Azure authentication, a separately managed Azure Pipeline must use a WIF-capable Azure task, reference the output connection name/ID and perform an authorized read of the selected scope. This example intentionally creates neither that pipeline nor YAML; static validation cannot prove a real token exchange. Inspect the exported claims through the module outputs and follow the root README's issuer migration guidance.

## Files and cleanup

`devops.tf` owns the local control-plane module call; `rbac.tf` owns external RBAC composition; `providers.tf`, `variables.tf`, `outputs.tf` and `terraform.tfvars.example` carry the runnable wrapper. Example 02 additionally has `key_vault.tf`.

When finished, an operator can run `tofu destroy` in this directory. Azure DevOps project deletion affects its contents; Key Vault soft deletion/name retention can delay reuse. Review your own environment before cleanup.
