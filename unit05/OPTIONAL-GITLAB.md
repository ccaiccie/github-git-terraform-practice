# Optional: try it on real GitLab (manual)

This guide is **optional**. The lab scripts never contact GitLab; you do these steps yourself, in your own throwaway project.
Do not use a work repository.

1. **Create a project.** On GitLab.com, create a new **private** project, for example `network-configs-lab`, with no template.
2. **Push the lab repository to it.** Use a fresh copy of the lab files: run `01-setup` and `02-translate` again in a new lab folder, then from the laptop repository:
   ```bash
   git remote add gitlab <your project's clone URL>
   git push gitlab main move-to-gitlab-ci
   ```
   Pushing the branch alone creates no pipeline, because of the workflow rules.
3. **Open a merge request** from `move-to-gitlab-ci` into `main`.
   - A merge request pipeline runs `validate`; `report` is not in it.
   - On GitLab.com, this uses GitLab-hosted runners and counts against your monthly compute minutes.
4. **Require the pipeline.** Go to Settings > Merge requests > Merge checks and select **Pipelines must succeed**. A merge request with a failed pipeline, or none at all, can no longer be merged.
5. **Protect main.** Go to Settings > Repository > Branch rules. The default branch is already protected. Review **Allowed to merge** and **Allowed to push and merge**.
6. **Approvals.**
   - On Free, anyone with the Developer role or higher can approve, but approval is optional.
   - Required approval rules (Settings > Merge requests > Merge request approvals) need Premium or Ultimate.
7. **Merge.** Then watch the pipeline on `main`, where `validate` runs first and `report` runs next.
8. **Clean up.** Delete the project when you are done (Settings > General > Advanced > Delete project).

You can also paste `.gitlab-ci.yml` into the pipeline editor, whose validation checks the syntax before you commit.

Optional, not covered here: the OpenTofu component example needs real cloud or provider credentials to plan and apply. Unit 6 covers Terraform automation.

## References
- Merge request pipelines: https://docs.gitlab.com/ci/pipelines/merge_request_pipelines/
- Merge request approvals: https://docs.gitlab.com/user/project/merge_requests/approvals/
- Protected branches: https://docs.gitlab.com/user/project/repository/branches/protected/
- Auto-merge and "Pipelines must succeed": https://docs.gitlab.com/user/project/merge_requests/auto_merge/
- GitLab-managed OpenTofu state: https://docs.gitlab.com/user/infrastructure/iac/terraform_state/
