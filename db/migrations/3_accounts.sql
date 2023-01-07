-- +migrate up
CREATE TABLE accounts (
  id  SERIAL  PRIMARY KEY,

  username  VARCHAR(16)   NOT NULL  COLLATE NOCASE  UNIQUE,
  password  TEXT          NOT NULL, -- bcrypt hashed
  gjp2      TEXT          NOT NULL,
  email     VARCHAR(254)  NOT NULL,

  -- todo: swap to proper rank system
  is_admin  INTEGER  NOT NULL  DEFAULT 0,

  -- 0: disabled, 1: only for friends, 2: open to all
  messages_enabled         INTEGER  NOT NULL  DEFAULT 2,
  comments_enabled         INTEGER  NOT NULL  DEFAULT 0,
  -- 0: disabled, 1: enabled
  friend_requests_enabled  INTEGER  NOT NULL  DEFAULT 1, -- frs enabled

  youtube_url  VARCHAR(30),
  twitter_url  VARCHAR(20),
  twitch_url   VARCHAR(20),

  created_at   TEXT    NOT NULL  DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'now'))
);

-- +migrate down
DROP TABLE accounts;