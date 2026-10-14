# 01 — Project with OIDC service connection

Creates one Azure DevOps project, single-tenant application/service principal, ARM WIF connection and federated credential. `rbac.tf` composes `terraform-az-fk-rbac` at a reviewed commit; no Azure client secret or certificate is created.


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
