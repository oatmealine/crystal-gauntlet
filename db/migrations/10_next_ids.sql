-- +migrate up
CREATE TABLE next_id (
  name  TEXT     NOT NULL,
  id    INTEGER  NOT NULL  DEFAULT 0
);

-- +migrate down
DROP TABLE next_id;