-- +migrate up
CREATE TABLE level_scores (
  account_id  INTEGER  NOT NULL  references accounts(id),
  level_id    INTEGER  NOT NULL  references levels(id),
  daily_id    INTEGER,

  percent   INTEGER  NOT NULL,
  attempts  INTEGER  NOT NULL  DEFAULT 0,
  clicks    INTEGER  NOT NULL  DEFAULT 0,
  coins     INTEGER  NOT NULL  DEFAULT 0,
  progress  TEXT     NOT NULL  DEFAULT "",
  time      INTEGER  NOT NULL,

  set_at   TEXT    NOT NULL  DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'now'))
);

-- +migrate down
DROP TABLE level_scores;