# OpenTofu component example (read-only)

These two files show the GitLab pattern from Unit 5. They are checked for structure by `05-opentofu-example`, never run.

- `.gitlab-ci.yml` includes the OpenTofu CI/CD component `validate-plan-apply`, pinned to release 5.1.0.
  - Merge requests run validate and plan.
  - On the default branch, apply is a manual job by default.
- `backend.tf` declares an empty `http` backend, so state is stored by GitLab (GitLab-managed Terraform/OpenTofu state).

In a real project, `backend.tf` sits inside `root_dir` (here `tofu/`) next to your `.tf` files. Unit 6 covers plan-on-merge-request and apply-after-merge in depth.
