# Azure DevOps with Terraform/OpenTofu – Training Examples

This directory contains all progressive examples used with the **terraform-az-fk-devops** module.
The examples are designed as **incremental building blocks**, starting with a passwordless ARM service connection and then introducing Key Vault-linked variable groups.

These examples are part of the **[FoggyKitchen.com training ecosystem](https://foggykitchen.com/courses)** and focus on shared Azure DevOps control-plane resources.

---

## 🧭 Example Overview

| Example | Title | Key Topics |
|:-------:|:------|:-----------|
| [01](01_project_with_oidc_service_connection/) | **Project with OIDC Service Connection** | Azure DevOps project, Entra application/SP, ARM WIF connection, federated trust, external FK RBAC |
| [02](02_project_with_keyvault_variable_group/) | **Project with Key Vault Variable Group** | Same foundation, composed Key Vault, Get/List access, externally populated secrets, staged variable-group link |

Each example builds on the **concepts** introduced in the previous one, but can be applied independently for learning and experimentation. Use different project names if keeping both configurations.

---

## ⚙️ How to Use

Each example directory contains:

- Terraform/OpenTofu configuration in responsibility-named `.tf` files
- A focused `README.md` with architecture, deployment, verification and cleanup guidance
- A safe `terraform.tfvars.example` containing only nonsecret placeholders
- Explicit provider version and external module commit pins
- An architecture diagram and a section for future Azure Portal evidence

Start with static checks:

```bash
cd examples/01_project_with_oidc_service_connection
cp terraform.tfvars.example terraform.tfvars
# Replace the nonsecret placeholder identifiers before continuing.
tofu init
tofu fmt -check
tofu validate
```

The recommended learning sequence is:
**01 → 02**

Read the selected example's Deployment Steps before provisioning it. Both require an existing organization and subscription, bootstrap authentication and administration rights. Both examples create their Resource Group in `resource_group.tf`. Example 02 first creates an empty vault with the group link disabled; populate secrets outside Terraform before enabling the link.

Both examples passed static validation. During initial module verification neither was planned or applied. Example 01 was subsequently deployed successfully (7 resources) in foggykitchendevops after resolving organization access; its screenshots are documented in the example README, and all 7 managed resources were subsequently destroyed successfully. Runtime OIDC token exchange is not yet tested. Example 02 has been deployed in two stages (8 foundation resources, then 1 linked variable group). The manually populated demo-secret is mapped by name; seven screenshots document the configuration. All 9 managed resources were subsequently destroyed successfully. Pipeline runtime secret retrieval has not been tested. Full output is available in [VERIFICATION.md](../VERIFICATION.md).

---

## 🧩 Design Principles

- One example = one architectural goal
- Passwordless ARM service connections with exact issuer/subject trust
- Azure RBAC and Key Vault lifecycle composed through dedicated modules
- Existing organization supplied explicitly; each example creates its RBAC scope as a Resource Group
- Secret names may be configured; secret values and provider credentials stay outside source control
- Static validation is not represented as successful runtime deployment

These examples intentionally avoid:

- Creating the Azure DevOps organization
- Pipeline definitions, pipeline YAML and stage/job/step logic
- Source repository lifecycle
- Resource Group creation inside the root module
- Networking or deployment-target creation
- Hidden dependencies between example states

---

## 🧩 Related Resources

- [FoggyKitchen Azure DevOps Module (terraform-az-fk-devops)](../)
- [FoggyKitchen Azure DevOps Pipeline Module (terraform-az-fk-devops-pipeline)](https://github.com/foggykitchen/terraform-az-fk-devops-pipeline) — separately built sibling
- [FoggyKitchen Azure RBAC Module (terraform-az-fk-rbac)](https://github.com/foggykitchen/terraform-az-fk-rbac)
- [FoggyKitchen Azure Key Vault Module (terraform-az-fk-key-vault)](https://github.com/foggykitchen/terraform-az-fk-key-vault)

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.
See [LICENSE](../LICENSE) for details.

---

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
