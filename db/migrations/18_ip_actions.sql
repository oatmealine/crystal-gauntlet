-- +migrate up
CREATE TABLE ip_actions (
  action  TEXT  NOT NULL,
  value   TEXT  NOT NULL,
  ip      TEXT  NOT NULL  DEFAULT 0
);

-- +migrate down
DROP TABLE ip_actions;