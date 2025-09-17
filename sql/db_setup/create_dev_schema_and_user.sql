-- idempotent SQL to create a development schema and an optional dev user
-- Run this as a DBA (superuser) or schema owner. Replace placeholder passwords.

-- Usage (psql):
--   psql -h <HOST> -U <SUPERUSER> -d <DBNAME> -v DEV_PASS="myDevPass" -v READONLY_PASS="myReadOnlyPass" -f sql/db_setup/create_dev_schema_and_user.sql
-- Notes:
--   * The script uses psql variable substitution. In the SQL below the variables are
--     referenced as :'DEV_PASS' and :'READONLY_PASS' which expands to SQL string
--     literals when psql is invoked with -v. Do NOT commit real passwords into the repo.
--   * If you prefer interactive entry, omit -v and psql will prompt for variables if used
--     with appropriate wrapper logic; otherwise DBAs can substitute values before running.

-- Create the dev schema if it does not exist
CREATE SCHEMA IF NOT EXISTS dev_mueller;

-- Create roles and users idempotently
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dev_role') THEN
    CREATE ROLE dev_role NOINHERIT;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dev_user') THEN
    -- Use the DEV_PASS psql variable (expanded as a SQL literal) when running with psql -v
    EXECUTE format('CREATE USER dev_user WITH PASSWORD %s', :'DEV_PASS');
    GRANT dev_role TO dev_user;
  END IF;
END
$$;

-- Allow dev_user to use and create objects in the dev schema
GRANT USAGE ON SCHEMA dev_mueller TO dev_user;
GRANT CREATE ON SCHEMA dev_mueller TO dev_user;

-- OPTIONAL: allow dev_user to read source schema(s) - adjust 'public' as needed
GRANT USAGE ON SCHEMA public TO dev_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO dev_user;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO dev_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO dev_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO dev_user;

-- Create a readonly_user if you want it later (idempotent)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'readonly_role') THEN
    CREATE ROLE readonly_role NOINHERIT;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'readonly_user') THEN
    -- Use the READONLY_PASS psql variable (expanded as a SQL literal) when running with psql -v
    EXECUTE format('CREATE USER readonly_user WITH PASSWORD %s', :'READONLY_PASS');
    GRANT readonly_role TO readonly_user;
  END IF;
END
$$;

-- Grant read-only access (adjust schema names as required)
GRANT USAGE ON SCHEMA public TO readonly_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO readonly_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO readonly_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO readonly_user;

-- Notes:
--  * Replace <STRONG_DEV_PASSWORD> and <STRONG_READONLY_PASSWORD> with secure values.
--  * ALTER DEFAULT PRIVILEGES statements should be run by the schema owner or a superuser
--    if you want them to apply to objects created by that owner in future.

