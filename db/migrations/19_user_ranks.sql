-- +migrate up
ALTER TABLE accounts DROP COLUMN is_admin;
ALTER TABLE accounts ADD COLUMN rank TEXT;

-- +migrate down
ALTER TABLE accounts DROP COLUMN rank;
ALTER TABLE accounts ADD COLUMN is_admin INTEGER NOT NULL DEFAULT 0;