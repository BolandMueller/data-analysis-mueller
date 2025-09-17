# DB setup — how to run

This document explains how to run the idempotent DB setup script in this repository locally and in CI.

Files
- `create_dev_schema_and_user.sql` — idempotent SQL that creates `dev_mueller` schema, `dev_user` and `readonly_user`. Uses psql variable substitution for passwords (`:DEV_PASS`, `:READONLY_PASS`).
- `README.md` — this file.

Prerequisites
- `psql` (PostgreSQL client) must be installed locally. On Ubuntu: `sudo apt-get install postgresql-client`.
- For local non-interactive runs, either set `PGPASSWORD` in the session or create `~/.pgpass` with permissions 600.
- The repository expects dbt installed (the wrapper uses `dbt`) for the dbt steps.

Secrets and environment variables
- CI (GitHub Actions) should have the following repository secrets defined:
  - `DB_HOST` — e.g. `pgsql.mueller1875.com`
  - `DB_USER` — e.g. `postgres`
  - `DB_PASS` — superuser password (used to authenticate psql)
  - `DB_PORT` — e.g. `5432`
  - `DB_NAME` — e.g. `Mueller`
  - `DB_SCHEMA` — e.g. `dev_mueller`

Optional secrets (if you want different created-user passwords):
  - `DEV_PASS` — password for `dev_user` (if not set, `DB_PASS` will be reused)
  - `READONLY_PASS` — password for `readonly_user` (if not set, `DB_PASS` will be reused)

Local run (PowerShell)
1. Open PowerShell and set session env vars (example):

```powershell
$env:DB_HOST = 'pgsql.mueller1875.com'
$env:DB_USER = 'postgres'
$env:DB_PASS = '<SUPERUSER_PASSWORD>'
$env:DB_PORT = '5432'
$env:DB_NAME = 'Mueller'
$env:DB_SCHEMA = 'dev_mueller'
$env:RUN_DB_SETUP = 'true'   # makes the wrapper run the DB setup step

# Run the wrapper which will run psql (DB setup) and then dbt steps
pwsh ./scripts/run-dbt-ci.ps1
```

2. Alternatively, run the SQL directly with psql (session PGPASSWORD):

```powershell
$env:PGPASSWORD = '<SUPERUSER_PASSWORD>'
psql -h "pgsql.mueller1875.com" -U "postgres" -p "5432" -d "Mueller" `
  -v DEV_PASS="'$env:PGPASSWORD'" `
  -v READONLY_PASS="'$env:PGPASSWORD'" `
  -f .\sql\db_setup\create_dev_schema_and_user.sql
Remove-Item Env:PGPASSWORD
```

CI run (GitHub Actions)
- The pipeline already installs `psql` and runs the DB setup SQL in the job. To use it, ensure the repository secrets above are configured in GitHub.
- If you want different created-user passwords, add `DEV_PASS` and `READONLY_PASS` secrets and they will be used automatically.

Order of operations (what to run and why)
1. Run the DB setup SQL (creates schema and users). This must be done first so that the `dev_schema` and users exist for dbt to target them.
2. Run dbt steps (the PowerShell wrapper does this: it writes a temporary `profiles.yml` then runs `dbt deps`, `dbt parse`, `dbt compile`, `dbt test`).

Security notes
- Do NOT commit passwords into the repository.
- In CI, GitHub Secrets are masked and safe to use for this purpose.
- Locally, prefer `~/.pgpass` for non-interactive authentication. `PGPASSWORD` is convenient for one-off runs but avoid storing it in shell rc files.

Troubleshooting
- If psql reports authentication failures: ensure `PGPASSWORD` (or ~/.pgpass) contains the correct password and that secrets are set correctly in GitHub.
- If the workflow fails to install psql on CI: ensure the runner has apt available (ubuntu-latest). For self-hosted runners, install `postgresql-client` manually.

Contact
- If you want me to change how passwords are handled (e.g., use a temporary `.pgpass` in CI), tell me and I will update the workflow and wrapper.
