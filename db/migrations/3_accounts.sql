-- +migrate up
CREATE TABLE accounts (
  id  SERIAL  PRIMARY KEY,

  username  TEXT  NOT NULL  COLLATE NOCASE  UNIQUE,
  password  TEXT  NOT NULL, -- bcrypt hashed
  gjp2      TEXT  NOT NULL,
  email     TEXT  NOT NULL,

  -- todo: swap to proper rank system
  is_admin  INTEGER  NOT NULL  DEFAULT 0,

  messages_enabled         INTEGER  NOT NULL  DEFAULT 1, -- messages from non-friends enabled
  friend_requests_enabled  INTEGER  NOT NULL  DEFAULT 1, -- frs enabled
  comments_enabled         INTEGER  NOT NULL  DEFAULT 0, -- able to see user's comments

  youtube_url  TEXT,
  twitter_url  TEXT,
  twitch_url   TEXT,

  created_at   TEXT    NOT NULL  DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'now'))
);

-- +migrate down
DROP TABLE accounts;