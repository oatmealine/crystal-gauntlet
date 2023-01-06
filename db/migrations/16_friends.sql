-- +migrate up

-- todo: maybe merge this and messages into one?
CREATE TABLE friend_requests (
  id  SERIAL  PRIMARY KEY,

  from_account_id  INTEGER  NOT NULL  references accounts(id),
  to_account_id    INTEGER  NOT NULL  references accounts(id),

  body     VARCHAR(140)  NOT NULL,

  created_at  TEXT  NOT NULL  DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'now')),
  read_at     TEXT
);

CREATE TABLE friend_links (
  account_id_1  INTEGER  references accounts(id),
  account_id_2  INTEGER  references accounts(id),

  read_at_1  TEXT,
  read_at_2  TEXT,

  created_at  TEXT  NOT NULL  DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'now'))
);

-- +migrate down
DROP TABLE friend_requests;
DROP TABLE friend_links;