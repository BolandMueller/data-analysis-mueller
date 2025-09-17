# Wrapper script for CI and local usage
# Generates a temporary profiles.yml from environment variables and runs dbt steps.
# Required env vars: DB_HOST, DB_USER, DB_PASS, DB_PORT, DB_NAME, DB_SCHEMA

$required = @('DB_HOST','DB_USER','DB_PASS','DB_PORT','DB_NAME','DB_SCHEMA')
foreach ($r in $required) {
  if (-not $env:$r) { Write-Error "Missing env var $r"; exit 1 }
}

$profiles = @"
mueller_analysis:
  outputs:
    dev:
      type: postgres
      host: ${env:DB_HOST}
      user: ${env:DB_USER}
      pass: ${env:DB_PASS}
      port: ${env:DB_PORT}
      dbname: ${env:DB_NAME}
      schema: ${env:DB_SCHEMA}
      threads: 4
  target: dev
"@

$profilesPath = Join-Path -Path (Get-Location) -ChildPath 'profiles.yml'
$profiles | Out-File -FilePath $profilesPath -Encoding utf8
Write-Host "Wrote temporary profiles.yml to $profilesPath"

# Run dbt steps
dbt deps
$dbtParse = & dbt parse
if ($LASTEXITCODE -ne 0) { Write-Error "dbt parse failed"; exit $LASTEXITCODE }
$dbtCompile = & dbt compile
if ($LASTEXITCODE -ne 0) { Write-Error "dbt compile failed"; exit $LASTEXITCODE }
$dbtTest = & dbt test
if ($LASTEXITCODE -ne 0) { Write-Error "dbt test failed"; exit $LASTEXITCODE }

Write-Host "dbt steps completed successfully"

# Clean up (optional) - comment out if you prefer to keep the profiles.yml for debugging
Remove-Item -Path $profilesPath -ErrorAction SilentlyContinue
Write-Host "Removed temporary profiles.yml"
