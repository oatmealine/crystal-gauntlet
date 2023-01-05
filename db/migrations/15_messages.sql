-- +migrate up
CREATE TABLE messages (
  id  SERIAL  PRIMARY KEY,

  from_account_id  INTEGER  NOT NULL,
  to_account_id    INTEGER  NOT NULL,

  subject  VARCHAR(35)   NOT NULL,
  body     VARCHAR(200)  NOT NULL,

  created_at  TEXT  NOT NULL  DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'now')),
  read_at     TEXT
);

-- +migrate down
DROP TABLE messages;