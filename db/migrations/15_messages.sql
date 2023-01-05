-- +migrate up
CREATE TABLE messages (
  id  SERIAL  PRIMARY KEY,

  from_account_id  INTEGER  NOT NULL,
  to_account_id    INTEGER  NOT NULL,

  subject  TEXT  NOT NULL,
  body     TEXT  NOT NULL,

  created_at  TEXT  NOT NULL  DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'now')),
  read_at     TEXT
);

-- +migrate down
DROP TABLE messages;