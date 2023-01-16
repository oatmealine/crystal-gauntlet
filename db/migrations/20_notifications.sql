-- +migrate up
CREATE TABLE notifications (
  id  SERIAL  PRIMARY KEY,

  account_id  INTEGER  NOT NULL  references accounts(id),
  type        TEXT     NOT NULL,
  target      INTEGER,           -- represents whatever is affected; for SQL querying assistance. INTEGER because it's always an ID, might be tweaked in the future
  details     TEXT     NOT NULL, -- a JSON of various things relevant to displaying the notification

  created_at  TEXT  NOT NULL  DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'now')),
  read_at     TEXT
);

-- +migrate down
DROP TABLE notifications;