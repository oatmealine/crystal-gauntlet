-- +migrate up
CREATE TABLE songs (
  id           SERIAL  PRIMARY KEY,
  name         TEXT     NOT NULL,
  author_id    INTEGER  NOT NULL,
  author_name  TEXT     NOT NULL,
  size         INTEGER  NOT NULL, -- in bytes
  download     TEXT     NOT NULL,
  disabled     INTEGER  NOT NULL  DEFAULT 0
);

-- +migrate down
DROP TABLE songs;