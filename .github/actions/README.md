# GitHub Actions for Network Infrastructure Management

This directory contains reusable GitHub Actions that standardize our infrastructure management workflows.

## Available Actions

### WireGuard VPN Connection

Establishes a WireGuard VPN connection to the network infrastructure.

```yaml
- name: Connect to VPN
  uses: ./.github/actions/wireguard-vpn
  with:
    config: ${{ secrets.WG_PEER_CONFIG }}
```

### Terraform Plan

Runs `terraform plan` and prepares the outputs for apply or PR comments.

```yaml
- name: Terraform Plan
  id: terraform-plan-action
  uses: ./.github/actions/terraform-plan
  with:
    token: ${{ github.token }}
    destroy: false # Set to true for terraform plan -destroy
    working_directory: '.' # Optional
    backend_config_file: '' # Optional
    var_file: '' # Optional
```

**Outputs:**
- `has_changes`: Boolean indicating if the plan has changes
- `plan_path`: Path to the saved plan file
- `plan_json_path`: Path to the saved plan JSON file

### Terraform Plan Comment

Posts a comment on a PR with the Terraform plan results.

```yaml
- name: Add PR Comment with Plan
  uses: ./.github/actions/terraform-plan-comment
  with:
    token: ${{ github.token }}
    repository: ${{ github.repository }}
    pr_number: ${{ github.event.pull_request.number }}
    plan_path: tfplan # Optional
    plan_json_path: tfplan.json # Optional
    working_directory: '.' # Optional
    title: 'Terraform Plan Summary' # Optional
```

### Terraform Apply

Applies a Terraform plan.

```yaml
- name: Apply Terraform Plan
  uses: ./.github/actions/terraform-apply
  with:
    token: ${{ github.token }}
    plan_path: tfplan
    working_directory: '.' # Optional
    backend_config_file: '' # Optional
    auto_approve: true # Optional
```

### Terraform Force Unlock

Force unlocks a Terraform state lock.

```yaml
- name: Force Unlock Terraform State
  uses: ./.github/actions/terraform-unlock
  with:
    token: ${{ github.token }}
    lock_id: ${{ github.event.inputs.lock_id }}
    working_directory: '.' # Optional
    backend_config_file: '' # Optional
```

## Benefits of Using These Actions

1. **Standardization**: Ensures consistent Terraform workflow patterns across all pipelines
2. **Maintainability**: Centralizes configuration details and reduces duplication
3. **Readability**: Makes workflows more concise and easier to understand
4. **Reusability**: Allows easy inclusion of standard patterns in new workflows
5. **Error Reduction**: Reduces the likelihood of errors from manually written scripts

## Usage Patterns

### Complete Terraform Workflow Example

```yaml
jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      # Establish VPN connection
      - name: Connect to VPN
        uses: ./.github/actions/wireguard-vpn
        with:
          config: ${{ secrets.WG_PEER_CONFIG }}
      
      # Plan changes
      - name: Terraform Plan
        id: terraform-plan
        uses: ./.github/actions/terraform-plan
        with:
          token: ${{ github.token }}

      # Post plan to PR if applicable
      - name: Add PR Comment with Plan
        if: github.event_name == 'pull_request' && steps.terraform-plan.outputs.has_changes == 'true'
        uses: ./.github/actions/terraform-plan-comment
        with:
          token: ${{ github.token }}
          repository: ${{ github.repository }}
          pr_number: ${{ github.event.pull_request.number }}

      # Apply if approved
      - name: Apply Changes
        if: github.ref == 'refs/heads/main' && steps.terraform-plan.outputs.has_changes == 'true'
        uses: ./.github/actions/terraform-apply
        with:
          token: ${{ github.token }}
          plan_path: tfplan
```

## Extending These Actions

To modify or extend these actions:

1. Update the action's `action.yml` file
2. Test changes in a feature branch
3. Once validated, update workflows to use the new version