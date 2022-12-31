-- +migrate up
CREATE TABLE comments (
  id  SERIAL  PRIMARY KEY,

  level_id    INTEGER  NOT NULL  references levels(id),
  user_id     INTEGER  NOT NULL  references users(id),
  comment     TEXT     NOT NULL,
  percent     INTEGER,

  created_at  TEXT  NOT NULL  DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'now')),
  likes  INTEGER  NOT NULL  DEFAULT 0
);

-- +migrate down
DROP TABLE comments;