-- +migrate up
CREATE TABLE account_comments (
  id  SERIAL  PRIMARY KEY,

  account_id  INTEGER       NOT NULL  references users(id),
  comment     VARCHAR(140)  NOT NULL,

  created_at  TEXT  NOT NULL  DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'now')),
  likes  INTEGER  NOT NULL  DEFAULT 0
);

-- +migrate down
DROP TABLE account_comments;