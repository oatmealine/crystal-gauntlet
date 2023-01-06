-- +migrate up

CREATE TABLE block_links (
  from_account_id  INTEGER  NOT NULL  references accounts(id),
  to_account_id    INTEGER  NOT NULL  references accounts(id),

  created_at  TEXT  NOT NULL  DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'now'))
);

-- +migrate down
DROP TABLE block_links;