-- +migrate up
CREATE TABLE quest_timer (
  account_id    INTEGER  NOT NULL  references accounts(id),
  next_at       TEXT     NOT NULL  DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'now'))
);

-- +migrate down
DROP TABLE quest_timer;