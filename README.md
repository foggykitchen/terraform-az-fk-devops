# terraform-az-fk-devops

This repository contains a reusable **Terraform / OpenTofu module** and progressive examples for provisioning the **shared Azure DevOps control-plane resources** around Azure Pipelines workflows.

It is part of the **[FoggyKitchen.com training ecosystem](https://foggykitchen.com/courses)** and composes with `terraform-az-fk-rbac`, `terraform-az-fk-key-vault`, and the separately built [terraform-az-fk-devops-pipeline](https://github.com/foggykitchen/terraform-az-fk-devops-pipeline) sibling.

Support expectations are documented in [SUPPORT.md](SUPPORT.md).

---

## Used By

This module is intended as a focused building block for higher-level [FoggyKitchen Landing Zone Orchestrator](https://github.com/foggykitchen/foggykitchen-landing-zone-orchestrator) compositions.

## 🎯 Purpose

Create one Azure DevOps project, one passwordless Azure Resource Manager service connection with an explicitly owned Entra application/service principal and federated trust, and optional variable groups. Azure DevOps / Azure Pipelines is the first-party Azure counterpart to OCI DevOps.

Pipeline YAML, including its stage/job/step graph, is **out of scope by design**. For YAML pipelines, the Azure DevOps Terraform provider's definition points at a YAML path in a repository; it does not expose that YAML's internal graph as resource attributes. The provider also supports some classic-pipeline job configuration, which is outside this module's scope. The sibling `terraform-az-fk-devops-pipeline` will own the definition pointer; delivery logic remains in the caller's repository.

## ✨ What the module does

The module creates:

- One `azuredevops_project` (private by default, Git project)
- One single-tenant `azuread_application` and `azuread_service_principal`, with explicit owners
- One manual `azuredevops_serviceendpoint_azurerm` using `WorkloadIdentityFederation`
- One `azuread_application_federated_identity_credential` trusting the exact issuer/subject exported by that endpoint
- Optional `azuredevops_variable_group` resources containing plain nonsecret key/value entries or Key Vault secret-name mappings

The module intentionally does **not** create:

- The Azure DevOps organization (an existing organization is required; this provider does not create organizations)
- Pipeline definitions, pipeline YAML, or stage/job/step logic
- Source repositories or GitHub repository connections
- Azure role assignments (compose `terraform-az-fk-rbac` externally)
- Resource Groups, VNets, or any Azure networking
- Target Azure resources such as VM Scale Sets or databases that a pipeline will later deploy
- Key Vaults or their secret values (compose the vault module externally)

Azure DevOps itself can provision default project contents, such as an initial repository/team, during project creation. This module declares no separate repository resource.

### OCI capability mapping

| OCI control-plane capability | Azure counterpart and ownership |
|---|---|
| DevOps project | Azure DevOps project; in scope |
| External connections | ARM WIF service connection; in scope. Source-host connections are excluded |
| ONS topic/project notifications | Azure DevOps notifications/service hooks exist, but no direct ONS project-binding equivalent; out of scope |
| OCI Logging service log/group | Azure DevOps audit and pipeline logs exist, but no equivalent OCI project service-log binding; export/monitoring configuration is out of scope |
| Mirrored source repositories | Azure Repos/import and external source integrations exist; source lifecycle is excluded |
| Deploy artifacts | Azure Artifacts feeds and pipeline artifacts exist; artifact publishing/consumption belongs outside this module |
| Deploy environments | Azure Pipelines environments exist; environment/approval lifecycle is outside this narrowly scoped module |
| Repository triggers | CI/PR/schedule triggers belong with pipeline YAML/definition in the sibling/caller, outside this module |
| Build/deploy stage graph | Azure Pipelines YAML owns the graph; not Terraform resource attributes |
| Shared configuration | Azure DevOps variable groups, optionally Key Vault-linked; in scope |

## Provider Notes

Live discovery on **2026-10-14** verified and pinned **microsoft/azuredevops = 1.16.0** (current major **1**) and **hashicorp/azuread = 3.10.0**. Exact pins keep the reviewed schema reproducible while lockfiles remain ignored. The root has no AzureRM resources or provider requirement. Examples pin **AzureRM = 4.81.0**, the latest 4.x, to satisfy the existing Key Vault module's compatibility range; the current overall AzureRM release is 5.9.0. See [DISCOVERY.md](DISCOVERY.md) for live source links and argument-level findings.

WIF is an authentication scheme on `azuredevops_serviceendpoint_azurerm`, not a separate resource. Its `credentials` block contains **only the application client ID**. No app password, client secret, or certificate is generated or stored. Azure Pipelines exchanges a short-lived OIDC token for an Azure token through Entra; external Azure RBAC determines what that identity may do.

Creation order is application → service principal → manual WIF endpoint → application federated credential. The credential uses `application.id` (the application resource ID), audience `api://AzureADTokenExchange`, and the endpoint's exported issuer/subject. Endpoint validation is disabled during creation because trust is established afterward. The `service_connection_id` output waits for that trust; variable groups also wait for it. This establishes configuration dependencies, not a guarantee that Entra propagation or a real pipeline login has been tested.

[Microsoft's current claim table](https://learn.microsoft.com/en-us/azure/devops/pipelines/release/troubleshoot-workload-identity?view=azure-devops) documents both formats:

| Issuer family | Issuer | Subject |
|---|---|---|
| Azure DevOps | `https://vstoken.dev.azure.com/{organization-id}` | `sc://{organization-name}/{project-name}/{service-connection-name}` |
| Microsoft Entra | `https://login.microsoftonline.com/{tenant-id}/v2.0` | `{entra-prefix}/sc/{organization-id}/{service-connection-id}` |

[Microsoft's configuration guidance](https://learn.microsoft.com/en-us/azure/devops/pipelines/release/configure-workload-identity?view=azure-devops) says new connections use the Entra issuer by default and eligible legacy Azure DevOps issuers retire **July 1, 2027**. The module consumes returned claims and never constructs either format. Provider 1.16.0 has no explicit issuer-family selector; inspect outputs after deployment and reconcile trust during conversion or renames. The provider docs' older private-preview note is superseded by Microsoft's GA guidance. No real-organization deployment was performed to verify which issuer the service returns. These are Azure DevOps claims, not GitHub Actions `repo:` claims.

### Prerequisites and authentication

- An **existing Azure DevOps organization** and its URL, e.g. `https://dev.azure.com/your-organization`. Configure it on the calling provider; organizations are created outside Terraform.
- Azure DevOps project creation, service connection administration and variable-group Library permissions. Public projects also require organization policy to permit them.
- An existing Azure subscription; configure the AzureAD provider for its Entra tenant. `service_connection.subscription_id` and `subscription_name` identify the target subscription; tenant ID comes from `azuread_client_config`.
- Entra rights to create/manage the application, service principal and federated credentials. Service-principal automation can use `Application.ReadWrite.OwnedBy` with ownership of both app and SP, or `Application.ReadWrite.All`; user authentication requires appropriate directory rights. The current provider principal is included as owner by default, following the Entra group precedent.
- Separate Azure authorization to assign RBAC through `terraform-az-fk-rbac`. The service connection does not grant subscription access itself.
- For Key Vault groups: an accessible vault, enabled existing secrets, and Get/List permission for this service principal. Secret names only are mapped; keys/certificates are not supported. Example 02 uses vault access policies; public-endpoint RBAC is also supported by Azure DevOps, with private-endpoint limitations documented by Microsoft.

Bootstrap provider authentication is separate from the pipeline service connection. Configure AzureDevOps provider authentication through its documented environment/OIDC options (organization URL can also use `AZDO_ORG_SERVICE_URL`); if your bootstrap method uses a PAT, inject it securely through the environment. Never put credentials in HCL or tfvars. AzureAD and example AzureRM providers can use an existing Azure CLI session or supported workload identity authentication. Do not assume the newly created connection authenticates the initial Terraform run.

## 📂 Repository Structure

```text
terraform-az-fk-devops/
├── examples/
│   ├── 01_project_with_oidc_service_connection/
│   ├── 02_project_with_keyvault_variable_group/
│   └── README.md
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── DISCOVERY.md
├── VERIFICATION.md
├── SUPPORT.md
├── LICENSE
├── .gitignore
└── README.md
```

Examples follow the current Azure convention: responsibility-named `devops.tf`, `rbac.tf`, optional `key_vault.tf`, plus `providers.tf`, `variables.tf`, `outputs.tf`, `terraform.tfvars.example`, and `README.md`. Root `variables.tf` follows this task's requested contract filename; older FoggyKitchen modules use `inputs.tf`.

## 🚀 Example Usage

```hcl
module "devops" {
  source = "./path/to/terraform-az-fk-devops"

  project_name = "fk-devops-demo"
  service_connection = {
    name              = "fk-azure-oidc"
    subscription_id   = var.subscription_id
    subscription_name = var.subscription_name
  }

  variable_groups = {
    configuration = {
      name      = "fk-configuration"
      variables = { environment = "dev" }
    }
  }
}

module "pipeline_access" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-rbac.git?ref=47dda4c1f7b851941695ced6c5b48cc314ed3883"

  scope                = var.existing_resource_group_id
  principal_id         = module.devops.principal_id
  role_definition_name = "Reader"
}
```

`Reader` is the smallest example permission for proving authenticated reads. Choose a workload-specific role at the narrowest target scope for deployments. Pipeline authors must authorize the individual pipeline to use the service connection and restricted variable groups; this module does not authorize all pipelines.

## 📥 Module Inputs

| Variable | Type | Required | Default | Description |
|---|---|:---:|---|---|
| `project_name` | `string` | yes | `—` | Azure DevOps project name. |
| `project_description` | `string` | no | `null` | Azure DevOps project description. |
| `project_visibility` | `string` | no | `"private"` | Azure DevOps project visibility: private or public. |
| `work_item_template` | `string` | no | `"Agile"` | Existing work item template name; empty string uses the organization default. |
| `service_connection` | `object` | yes | `—` | One passwordless Azure Resource Manager service connection and its application name. |
| `owners` | `set(string)` | no | `[]` | Additional Entra object IDs owning both the application and service principal. |
| `include_current_principal_as_owner` | `bool` | no | `true` | Include the AzureAD provider principal as application and service principal owner. |
| `variable_groups` | `map(object)` | no | `{}` | Plain nonsecret variables or Key Vault secret-name mappings, keyed by logical group name. |

See [variables.tf](variables.tf) for the exact nested object schemas and validations.

`service_connection` requires `name`, `subscription_id`, `subscription_name`; optional `application_display_name` defaults to `{project_name}-{name}` and `description` defaults to `Managed by Terraform/OpenTofu with workload identity federation`.

Each `variable_groups` entry requires `name`; optional `description` defaults null and `allow_access` defaults false. Choose exactly one mode:

- Plain: nonempty `variables = map(string)`, with no `key_vault` or `secret_names`. These values are **nonsecret** and appear in state.
- Key Vault: `key_vault = { name = "existing-vault", search_depth = 20 }` and nonempty `secret_names = set(string)`, with no plain variables. The service endpoint is the module's WIF connection. `search_depth` must be a positive integer. No secret values enter the module.

Group names must be unique and group/variable/vault names nonblank. `allow_access = true` shares a group with all project pipelines; leave the default false and authorize callers individually. Linked secret additions/removals require updating the input set; existing secret value rotations are fetched at runtime. The provider enumerates secret metadata and validates enabled names during creation, so authorization, network access and secret population must already be ready.

## 📤 Module Outputs

| Output | Description |
|---|---|
| `project_id` | Azure DevOps project ID. |
| `project_name` | Azure DevOps project name. |
| `service_connection_id` | ARM service connection ID, ready after federated trust creation. |
| `service_connection_name` | ARM service connection name. |
| `application_id` | Entra application resource ID. |
| `client_id` | Entra application client ID used by the service connection. |
| `principal_id` | Entra service principal object ID for external RBAC composition. |
| `tenant_id` | Entra tenant ID used by the AzureAD provider. |
| `workload_identity_federation_issuer` | Exact OIDC issuer returned by Azure DevOps. |
| `workload_identity_federation_subject` | Exact OIDC subject returned by Azure DevOps. |
| `federated_identity_credential_id` | Entra federated identity credential resource ID. |
| `variable_group_ids` | Variable group IDs keyed by logical name. |

## Typical Integration Pattern

1. Supply the existing organization and bootstrap provider credentials externally.
2. Create shared project/WIF trust with this module.
3. Grant access externally with `terraform-az-fk-rbac`; create a vault with `terraform-az-fk-key-vault` if needed.
4. Populate Key Vault outside Terraform, then link selected secret names.
5. Compose the separately built `terraform-az-fk-devops-pipeline` definition pointer and authorize its pipeline ID to use the connection/groups. Keep pipeline YAML in the source repository.

## 🧭 Examples

- [01_project_with_oidc_service_connection](examples/01_project_with_oidc_service_connection/): smallest project/WIF/RBAC configuration, using Reader on an existing scope.
- [02_project_with_keyvault_variable_group](examples/02_project_with_keyvault_variable_group/): adds a composed Key Vault and a staged secret-name-only variable-group link.

See [examples](examples/README.md). Dependencies are pinned to live-reviewed commit SHAs. Examples target existing resource groups and create no pipeline or YAML template.

## 🧠 Design Philosophy

- Long-lived control-plane resources stay separate from delivery logic.
- Entra identity and service connection trust form one coherent passwordless unit.
- Azure RBAC stays in its dedicated module; vaults and Azure deployment targets remain independently owned.
- Identity outputs are composition points, and service connection readiness includes trust creation.

## 🧩 Related Modules & Training

- [terraform-oci-fk-devops](https://github.com/foggykitchen/terraform-oci-fk-devops)
- [terraform-az-fk-devops-pipeline](https://github.com/foggykitchen/terraform-az-fk-devops-pipeline) — separately built sibling
- [terraform-az-fk-rbac](https://github.com/foggykitchen/terraform-az-fk-rbac)
- [terraform-az-fk-key-vault](https://github.com/foggykitchen/terraform-az-fk-key-vault)
- [terraform-az-fk-entra-group](https://github.com/foggykitchen/terraform-az-fk-entra-group)
- [terraform-az-fk-entra-user](https://github.com/foggykitchen/terraform-az-fk-entra-user)
- [terraform-az-fk-managed-identity](https://github.com/foggykitchen/terraform-az-fk-managed-identity)

## Contributing

This project is open source. Contributions are welcome through pull requests.

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.
See [LICENSE](LICENSE) for details.

---

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
