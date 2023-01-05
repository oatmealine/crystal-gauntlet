-- +migrate up
CREATE TABLE small_chests (
  account_id    INTEGER  NOT NULL  references accounts(id),
  total_opened  INTEGER  NOT NULL  DEFAULT 0,
  next_at       TEXT     NOT NULL  DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'now'))
);

CREATE TABLE large_chests (
  account_id    INTEGER  NOT NULL  references accounts(id),
  total_opened  INTEGER  NOT NULL  DEFAULT 0,
  next_at       TEXT     NOT NULL  DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'now'))
);

-- +migrate down
DROP TABLE small_chests;
DROP TABLE large_chests;