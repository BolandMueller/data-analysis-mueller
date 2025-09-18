# Wrapper script for CI and local usage
# Generates a temporary profiles.yml from environment variables and runs dbt steps.
# Required env vars: DB_HOST, DB_USER, DB_PASS, DB_PORT, DB_NAME, DB_SCHEMA

$required = @('DB_HOST','DB_USER','DB_PASS','DB_PORT','DB_NAME','DB_SCHEMA')
foreach ($r in $required) {
  # Use Test-Path on the env: provider to avoid invalid dynamic variable reference
  if (-not (Test-Path "env:$r")) { Write-Error "Missing env var $r"; exit 1 }
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

# Optionally run DB setup SQL if requested (RUN_DB_SETUP=true)
if ($env:RUN_DB_SETUP -and $env:RUN_DB_SETUP.ToLower() -eq 'true') {
  Write-Host "RUN_DB_SETUP is true — running DB setup SQL before dbt steps"

  # Determine passwords for created users: prefer DEV_PASS/READONLY_PASS if set, otherwise fall back to DB_PASS
  $devPassVar = if ($env:DEV_PASS) { $env:DEV_PASS } else { $env:DB_PASS }
  $roPassVar = if ($env:READONLY_PASS) { $env:READONLY_PASS } else { $env:DB_PASS }

  # Check for psql availability
  $psqlPath = Get-Command psql -ErrorAction SilentlyContinue
  if (-not $psqlPath) {
    Write-Host "psql not found in PATH — attempting to install (apt-get)"
    if ($IsWindows) {
      Write-Error "Automatic install of psql is not supported on Windows in this script. Please install psql and rerun."
      exit 1
    } else {
      # Try apt-get install (CI runner is ubuntu-latest)
      & sudo apt-get update
      & sudo apt-get install -y postgresql-client
    }
  }

  # Run the SQL using PGPASSWORD for non-interactive auth (CI: safe when set from secrets)
  $env:PGPASSWORD = $env:DB_PASS

  if ($env:SKIP_CREATE_USERS -and $env:SKIP_CREATE_USERS.ToLower() -eq 'true') {
    Write-Host "SKIP_CREATE_USERS is true — running schema-only SQL"
    $psqlCmd = "psql -h `"$($env:DB_HOST)`" -U `"$($env:DB_USER)`" -p `"$($env:DB_PORT)`" -d `"$($env:DB_NAME)`" -f sql/db_setup/create_schema_only.sql"
  } else {
    $psqlCmd = "psql -h `"$($env:DB_HOST)`" -U `"$($env:DB_USER)`" -p `"$($env:DB_PORT)`" -d `"$($env:DB_NAME)`" -v DEV_PASS='`"$devPassVar`"' -v READONLY_PASS='`"$roPassVar`"' -f sql/db_setup/create_dev_schema_and_user.sql"
  }
  Write-Host "Running: $psqlCmd"
  iex $psqlCmd

  # Clear sensitive env
  Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
  Write-Host "DB setup SQL completed"
}

# Run dbt steps: install deps and build (materialize models, then run tests)
dbt deps
$dbtBuild = & dbt build --profiles-dir . --target dev
if ($LASTEXITCODE -ne 0) { Write-Error "dbt build failed"; exit $LASTEXITCODE }

Write-Host "dbt steps completed successfully"

# Clean up (optional) - comment out if you prefer to keep the profiles.yml for debugging
Remove-Item -Path $profilesPath -ErrorAction SilentlyContinue
Write-Host "Removed temporary profiles.yml"
