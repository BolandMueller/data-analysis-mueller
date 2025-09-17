-- Create dev schema (run as a superuser or owner)
CREATE SCHEMA IF NOT EXISTS dev_mueller;

-- Create a role for dev work (optional grouping)
CREATE ROLE dev_role NOINHERIT;

-- Create a dedicated user for CI/dev and assign password
CREATE USER dev_user WITH PASSWORD 'KylorMagnifi1998!';

-- Grant the role to the user (optional)
GRANT dev_role TO dev_user;

-- Allow the user to use and create objects in the dev schema
GRANT USAGE ON SCHEMA dev_mueller TO dev_user;
GRANT CREATE ON SCHEMA dev_mueller TO dev_user;

-- If you want dev_user to be able to SELECT from source schemas too:
GRANT USAGE ON SCHEMA public TO dev_user; -- adjust source schema
GRANT SELECT ON ALL TABLES IN SCHEMA public TO dev_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO dev_user;
