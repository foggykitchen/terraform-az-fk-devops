# Example 02: Project with Key Vault Variable Group

In this second Azure DevOps example, we extend the **project and OIDC service connection** with a **Key Vault-linked variable group** using **Terraform / OpenTofu**.

The example composes `terraform-az-fk-devops`, `terraform-az-fk-rbac` and `terraform-az-fk-key-vault`. Only existing secret names are mapped into Azure DevOps; secret values are populated outside Terraform.

---

## 🧭 Architecture Overview

The project, application, service principal and WIF trust follow Example 01. The Key Vault module grants that service principal Get/List access through vault access policies. Once the vault contains enabled secrets, the variable group links their names through the passwordless ARM connection.

```mermaid
flowchart LR
    P[Azure DevOps project] --> C[ARM WIF service connection]
    A[Entra application and service principal] --> C
    C --> F[Application federated credential]
    A --> R[External FK RBAC assignment]
    R --> T[Example Resource Group]
    A --> K[FK Key Vault with Get/List policy]
    K --> G[Key Vault-linked variable group]
    C --> G
    E[External secret management] --> K
```

This example creates:

- The project, Entra identity and federated trust from Example 01
- An external FK RBAC assignment at the example Resource Group scope
- One Resource Group in `resource_group.tf`
- One Key Vault through `terraform-az-fk-key-vault`, in the Resource Group created by this example
- A Get/List access policy for the pipeline service principal
- One Key Vault-linked variable group when `link_variable_group = true`

The vault uses public endpoint access and vault access policies. The provider must be able to enumerate enabled secret metadata through Azure DevOps. No secret values, pipeline definition, YAML, networking or deployment targets are created.

The vault receives the service principal output, and the variable group receives the vault name output. Keep these resource-level dependencies; adding module-wide `depends_on` between the DevOps and vault modules would introduce a cycle.

---

## 🎯 Why this example exists

This example introduces **shared pipeline configuration without putting secret values in Terraform**.

It focuses on:

- Key Vault-linked variable groups supported by AzureDevOps provider 1.16.0
- WIF-based access to Key Vault using the same ARM service connection
- Explicit Get/List permissions and externally populated secrets
- A staged workflow that satisfies the provider's existing-secret check
- Restricted group access, with individual pipeline authorization

---

## 🚀 Deployment Steps

### Prerequisites

- An existing Azure DevOps organization and permissions to create projects, service connections and variable groups
- An existing Azure subscription, with permission to create Resource Groups and assign Azure roles
- Entra permissions to create and manage applications, service principals and federated credentials
- Bootstrap authentication configured externally for the AzureDevOps, AzureAD and AzureRM providers

Copy `terraform.tfvars.example` to ignored `terraform.tfvars` and replace the placeholder identifiers. Set `resource_group_name` and `location`; the example creates the group and uses its ID as the RBAC scope. The example defaults to `Reader` for authenticated reads; select a narrowly scoped deployment role for a later pipeline that needs writes. Keep provider credentials outside HCL and tfvars.

### Stage 1 — Create the project, trust and vault

Keep the initial settings:

```hcl
link_variable_group = false
secret_names        = []
```

Initialize and validate the configuration:

```bash
cp terraform.tfvars.example terraform.tfvars
# Replace the nonsecret placeholder identifiers before continuing.
tofu init
tofu fmt -check
tofu validate
```

To provision the reviewed first-stage configuration in your own environment:

```bash
tofu apply
```

### Stage 2 — Populate the vault and enable the link

Have an authorized operator populate the vault through an external secret-management process. The pipeline identity has only Get/List permissions; the bootstrap AzureRM principal receives a separate Get/List/Set access policy to populate the vault outside Terraform. Never put secret values in Terraform or tfvars.

Set the existing enabled secret names and enable the variable group:

```hcl
link_variable_group = true
secret_names        = ["demo-secret"]
```

Reconcile the updated configuration:

```bash
tofu apply
```

The AzureDevOps provider checks that named secrets exist when creating the group, so an empty new vault cannot satisfy the second stage. Allow time for Entra/access-policy propagation and ensure Azure DevOps can reach the vault endpoint. The Library service's network path may differ from the agent's path.

Authorize the intended pipeline to use both the connection and variable group. `allow_access` remains false. Existing secret value rotations are fetched at runtime; adding or removing mapped names requires updating `secret_names`. Only secrets are supported, not keys or certificates. The provider's `search_depth` defaults to 20 and can be increased through the root module contract.

`resource_group.tf` creates the group; `devops.tf`, `rbac.tf` and `key_vault.tf` separate control-plane, RBAC and vault composition. The external modules are pinned to reviewed commits.

---

## 🖼️ Azure Portal View

<img src="02_project_with_keyvault_variable_group_project_overview.jpg" width="900"/>

*Figure 1. Private Azure DevOps project fk-devops-demo in the foggykitchendevops organization.*

<img src="02_project_with_keyvault_variable_group_service_connection.jpg" width="900"/>

*Figure 2. Azure Resource Manager service connection fk-azure-oidc configured with Workload Identity federation (Manual), without a stored Azure client secret.*

<img src="02_project_with_keyvault_variable_group_key_vault_overview.jpg" width="900"/>

*Figure 3. Standard Key Vault fk-devops-kv-9f064c73 in the foggykitchen-rg Resource Group and West Europe region, with soft deletion enabled.*

<img src="02_project_with_keyvault_variable_group_access_policy.jpg" width="900"/>

*Figure 4. Key Vault access policy granting the fk-devops-demo-fk-azure-oidc application service principal Get and List permissions for secrets.*

<img src="02_project_with_keyvault_variable_group_role_assignment.jpg" width="900"/>

*Figure 5. Reader role inherited by the Key Vault from its Resource Group scope. This management-plane assignment is separate from the secret Get/List access policy shown in Figure 4.*

<img src="02_project_with_keyvault_variable_group_secret_names.jpg" width="900"/>

*Figure 6. Enabled demo-secret created manually in Key Vault outside Terraform. Only the secret name and status are shown; its value is not exposed.*

<img src="02_project_with_keyvault_variable_group_variable_group.jpg" width="900"/>

*Figure 7. Azure DevOps variable group fk-key-vault-secrets linked to fk-devops-kv-9f064c73 through the fk-azure-oidc service connection, mapping the enabled demo-secret by name.*

---

## ✅ Test Results

Static verification completed on **October 14, 2026** with OpenTofu **1.11.6**:

| Check | Result |
|---|---|
| `tofu fmt -check` | Passed |
| `tofu init` | Passed |
| `tofu validate` | Passed |

Full command output, including the initial sandbox plugin error and successful rerun, is recorded in [VERIFICATION.md](../../VERIFICATION.md).

A later user-authorized stage 1 apply completed successfully:

```text
Apply complete! Resources: 8 added, 0 changed, 0 destroyed.
```

Stage 1 created the project, WIF trust, Resource Group, external RBAC and Key Vault. After demo-secret was populated manually outside Terraform, stage 2 enabled the link and created the variable group:

```text
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

The resulting `variable_group_ids` output contains `vault = "1"`. The provider successfully validated the existing secret metadata through the WIF service connection, and the Library view confirms the enabled mapping. The secret value was not supplied to Terraform. Pipeline runtime retrieval of the secret has not been tested. To verify passwordless authentication after deployment, authorize an independently managed Azure Pipeline to use the connection, then run a WIF-capable Azure task that reads the selected scope. Pipeline definitions and YAML belong to the separately built [terraform-az-fk-devops-pipeline](https://github.com/foggykitchen/terraform-az-fk-devops-pipeline) sibling and the caller's repository.

The outputs expose the service connection ID/name and exact issuer/subject. Trust creation and the RBAC assignment are dependencies of the example's connection ID output; Entra and RBAC propagation can still take time. See the root [Provider Notes](../../README.md#provider-notes) before issuer conversion or connection renaming.

---

## 🧹 Cleanup

```bash
tofu destroy
```

Cleanup completed successfully after collecting the screenshots:

```text
Destroy complete! Resources: 9 destroyed.
```

The local state contains no remaining managed resources. The external Azure DevOps organization was retained.

Review project contents and vault data before deletion. Key Vault soft deletion and name retention can delay name reuse. The example Resource Group is also removed. The existing subscription and target deployment resources remain externally managed.

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.
See [LICENSE](../../LICENSE) for details.

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
