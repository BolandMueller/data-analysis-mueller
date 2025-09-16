dbt setup notes

This repo uses dbt. Follow these steps to set up a safe development environment and CI.

1) Profiles
- Copy `profiles.yml.example` to `~/.dbt/profiles.yml` or set the environment variables shown in the file.
- Use a read-only or limited-permission user for the `dev` target.

2) Dev schema
- Use a non-production schema (e.g., `dev_mueller`) for development materializations.
- Set `DB_SCHEMA` env var before running dbt commands.

3) Running locally
- Install dbt (Postgres adapter) matching CI: `pip install dbt-postgres==1.10.11`
- Validate: `dbt debug --profiles-dir ~/.dbt` or `dbt debug` if profiles already installed.
- Run: `dbt deps && dbt compile && dbt build --select path:mueller_analysis/models`

4) CI
- This repo includes a GitHub Actions template at `.github/workflows/dbt-ci.yml`.
- Add secrets in GitHub repository settings: `DB_HOST`, `DB_USER`, `DB_PASS`, `DB_PORT`, `DB_NAME`, `DB_SCHEMA`.

5) Safety tips
- Don't run write-heavy jobs against production. Use read-only users or a dev schema.
- Add schema + data tests and run them in CI before merging.
- Store credentials in a secrets manager. Rotate credentials periodically.

6) Troubleshooting
- If dbt commands fail in CI due to missing secrets, add them in repo Settings -> Secrets.
- If tests fail locally, run `dbt compile` and inspect `target/compiled` for compiled SQL.
