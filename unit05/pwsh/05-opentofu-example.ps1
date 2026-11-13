# Structure check of the OpenTofu component example (GitLab-managed state). Nothing is run, nothing contacts GitLab.
. (Join-Path $PSScriptRoot 'lab-env.ps1'); Assert-Lab
$ex = Join-Path $Files 'gitlab' 'opentofu-example'
Step 'The example pipeline'
Read-Lines (Join-Path $ex '.gitlab-ci.yml') | ForEach-Object { Write-Host $_ }
Step 'Lint the example'
if (-not (Test-TofuExample $ex)) { exit 1 }
Step 'Lint a copy that follows ~latest (expected to fail)'
$bad = Join-Path $Lab 'tofu-latest'; New-Item -ItemType Directory -Path $bad -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $ex 'backend.tf') -Destination $bad
Write-Lf (Join-Path $bad '.gitlab-ci.yml') (Read-Lines (Join-Path $ex '.gitlab-ci.yml') | ForEach-Object { $_ -replace '@5\.1\.0$', '@~latest' })
if (Test-TofuExample $bad) { throw 'UNEXPECTED: unpinned copy passed' }
Remove-Item -LiteralPath $bad -Recurse -Force
