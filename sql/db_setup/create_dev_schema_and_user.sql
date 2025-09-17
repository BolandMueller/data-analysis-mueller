-- idempotent SQL to create a development schema and an optional dev user
-- Run this as a DBA (superuser) or schema owner. Replace placeholder passwords.

-- Create the dev schema if it does not exist
CREATE SCHEMA IF NOT EXISTS dev_mueller;

-- Create roles and users idempotently
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dev_role') THEN
    CREATE ROLE dev_role NOINHERIT;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dev_user') THEN
    CREATE USER dev_user WITH PASSWORD '<STRONG_DEV_PASSWORD>';
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
    CREATE USER readonly_user WITH PASSWORD '<STRONG_READONLY_PASSWORD>';
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
