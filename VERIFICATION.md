# Verification — 2026-10-14

OpenTofu v1.11.6, darwin_arm64. Only formatting, initialization and validation were run; no plan or apply, and no subscription/organization runtime authentication test. Initial installation selected AzureDevOps 1.16.0, AzureAD 3.10.0, and AzureRM 4.81.0 in examples. Final init output below reuses these installations.

## Initial sandbox validation failure (full output)

Root `tofu validate -no-color` initially exited 1 inside the sandbox. The same command passed outside it; the complete initial error is retained here.

```text
Error: failed to read schema for azuread_application_federated_identity_credential.this in registry.opentofu.org/hashicorp/azuread: failed to instantiate provider "registry.opentofu.org/hashicorp/azuread" to obtain schema: Unrecognized remote plugin message:
Failed to read any lines from plugin's stdout
This usually means
  the plugin was not compiled for this architecture,
  the plugin is missing dynamic-link libraries necessary to run,
  the plugin is not executable by this process due to file permissions, or
  the plugin failed to negotiate the initial go-plugin protocol handshake

Additional notes about plugin:
  Path: .terraform/providers/registry.opentofu.org/hashicorp/azuread/3.10.0/darwin_arm64/terraform-provider-azuread
  Mode: -rwxr-xr-x
  Owner: 501 [mlinxfeld] (current: 501 [mlinxfeld])
  Group: 20 [staff] (current: 20 [staff])
  MachO architecture: CpuArm64 (current architecture: arm64)
```

## Final checks — full stdout/stderr

All nine final commands exited 0. A successful fmt check produces no output; its empty output block is intentional. Checks were run outside the sandbox so providers could start their local plugin channels.

### .

Command: `tofu fmt -check -no-color` — exit 0

```text
```

Command: `tofu init -no-color` — exit 0

```text

Initializing the backend...

Initializing provider plugins...
- Reusing previous version of hashicorp/azuread from the dependency lock file
- Reusing previous version of microsoft/azuredevops from the dependency lock file
- Using previously-installed hashicorp/azuread v3.10.0
- Using previously-installed microsoft/azuredevops v1.16.0

OpenTofu has been successfully initialized!

You may now begin working with OpenTofu. Try running "tofu plan" to see
any changes that are required for your infrastructure. All OpenTofu commands
should now work.

If you ever set or change modules or backend configuration for OpenTofu,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

Command: `tofu validate -no-color` — exit 0

```text
Success! The configuration is valid.
```

### examples/01_project_with_oidc_service_connection

Command: `tofu fmt -check -no-color` — exit 0

```text
```

Command: `tofu init -no-color` — exit 0

```text

Initializing the backend...
Initializing modules...

Initializing provider plugins...
- Reusing previous version of hashicorp/azurerm from the dependency lock file
- Reusing previous version of hashicorp/azuread from the dependency lock file
- Reusing previous version of microsoft/azuredevops from the dependency lock file
- Using previously-installed hashicorp/azurerm v4.81.0
- Using previously-installed hashicorp/azuread v3.10.0
- Using previously-installed microsoft/azuredevops v1.16.0

OpenTofu has been successfully initialized!

You may now begin working with OpenTofu. Try running "tofu plan" to see
any changes that are required for your infrastructure. All OpenTofu commands
should now work.

If you ever set or change modules or backend configuration for OpenTofu,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

Command: `tofu validate -no-color` — exit 0

```text
Success! The configuration is valid.
```

### examples/02_project_with_keyvault_variable_group

Command: `tofu fmt -check -no-color` — exit 0

```text
```

Command: `tofu init -no-color` — exit 0

```text

Initializing the backend...
Initializing modules...

Initializing provider plugins...
- Reusing previous version of hashicorp/azuread from the dependency lock file
- Reusing previous version of microsoft/azuredevops from the dependency lock file
- Reusing previous version of hashicorp/azurerm from the dependency lock file
- Using previously-installed hashicorp/azurerm v4.81.0
- Using previously-installed hashicorp/azuread v3.10.0
- Using previously-installed microsoft/azuredevops v1.16.0

OpenTofu has been successfully initialized!

You may now begin working with OpenTofu. Try running "tofu plan" to see
any changes that are required for your infrastructure. All OpenTofu commands
should now work.

If you ever set or change modules or backend configuration for OpenTofu,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

Command: `tofu validate -no-color` — exit 0

```text
Success! The configuration is valid.
```

## Contract and scope checks

README tables were generated from and independently checked against the declarations. All **8 inputs** match names/order/types/required flags/defaults/descriptions; all **12 outputs** match names/order/descriptions. Nested schemas are documented and linked to variables.tf. No missing or extra table rows.

`git check-ignore` confirmed root and both example `.terraform.lock.hcl` files are ignored. No provider caches, state, plans, real tfvars, passwords, certificates, client secrets, pipeline resources or YAML templates are included. Placeholder UUIDs/URLs and secret names are nonsecret examples. RBAC is only an external FK module call in each example. No existing repository was modified.

## Final source tree

Matches the established root module plus progressive numbered examples shape, with responsibility-named example files. Root variables.tf is the task-requested equivalent of the precedent's inputs.tf. DISCOVERY.md and VERIFICATION.md add the requested evidence. Generated .terraform directories and ignored lockfiles are omitted.

```text
terraform-az-fk-devops/
├── .gitignore
├── DISCOVERY.md
├── LICENSE
├── README.md
├── SUPPORT.md
├── VERIFICATION.md
├── main.tf
├── outputs.tf
├── variables.tf
├── versions.tf
└── examples/
    ├── README.md
    ├── 01_project_with_oidc_service_connection/
    │   ├── README.md
    │   ├── devops.tf
    │   ├── outputs.tf
    │   ├── providers.tf
    │   ├── rbac.tf
    │   ├── terraform.tfvars.example
    │   └── variables.tf
    └── 02_project_with_keyvault_variable_group/
        ├── README.md
        ├── devops.tf
        ├── key_vault.tf
        ├── outputs.tf
        ├── providers.tf
        ├── rbac.tf
        ├── terraform.tfvars.example
        └── variables.tf
```
