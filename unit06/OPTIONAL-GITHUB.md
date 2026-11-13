# Optional: the real workflows on GitHub (manual)

This guide is **optional**. The lab never contacts GitHub or any cloud. Do this only in your own throwaway repository and a sandbox cloud account. Real `terraform apply` creates real resources, which may cost money.

1. **Code.** Replace `lab_vlan` in `infra/main.tf` with a real, low-risk resource. Add a provider block and a remote backend.
   - Example: an S3 backend with `use_lockfile = true`, so state is shared and locked.
2. **OIDC.** In your cloud account, create an OIDC trust for GitHub and two roles:
   - a read-only role for plans (`PLAN_ROLE_ARN`);
   - an apply role that only the `production` environment of your repository may assume (`APPLY_ROLE_ARN`).

   Store both ARNs as repository **variables**, not secrets. They are not passwords.
3. **Environment.** Under Settings > Environments, create `production` and add yourself as a required reviewer.
   - Required reviewers on private repositories need GitHub Enterprise; public repositories have them on every plan.
4. **Branch protection.** Protect `main` and require the check `terraform-plan / plan` (see Unit 4).
5. **Try the flow.**
   - Open a pull request and read the plan comment.
   - Merge, approve the deployment, and watch the apply.
   - Change the resource by hand in the cloud console, then run `terraform-drift` with **Run workflow** (workflow_dispatch). It should open an issue.
6. **Clean up.**
   - Run `terraform destroy` from a trusted machine with the apply role, or remove the resources in the console.
   - Then delete the repository, the roles and the OIDC trust.

## References
- terraform plan, `-detailed-exitcode`: https://developer.hashicorp.com/terraform/cli/commands/plan
- S3 backend locking: https://developer.hashicorp.com/terraform/language/backend/s3
- OIDC in GitHub Actions: https://docs.github.com/en/actions/concepts/security/openid-connect
- Environments and required reviewers: https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments
- Schedule event: https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows
