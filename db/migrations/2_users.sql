-- +migrate up
CREATE TABLE users (
  id            SERIAL   PRIMARY KEY,
  -- on a registered account, account_id refers to the
  -- account ID - however, pre 2.0, instead udid referred
  -- to the user's UUID or UDID, depending on platform.
  -- UUID and UDID are unique ids assigned for green
  -- username users
  --
  -- in short, if `registered`, use account_id, else, use udid
  udid          TEXT,
  account_id    INTEGER  references accounts(id),
  registered    INTEGER  NOT NULL,

  username  TEXT  NOT NULL,

  stars           INTEGER  NOT NULL  DEFAULT 0,
  demons          INTEGER  NOT NULL  DEFAULT 0,
  coins           INTEGER  NOT NULL  DEFAULT 0,
  user_coins      INTEGER  NOT NULL  DEFAULT 0,
  diamonds        INTEGER  NOT NULL  DEFAULT 0,
  orbs            INTEGER  NOT NULL  DEFAULT 0,
  creator_points  INTEGER  NOT NULL  DEFAULT 0,

  completed_levels  INTEGER  NOT NULL  DEFAULT 0,

  icon_type  INTEGER  NOT NULL  DEFAULT 0, -- icon to display in comments, etc
  color1     INTEGER  NOT NULL  DEFAULT 0,
  color2     INTEGER  NOT NULL  DEFAULT 3,
  cube       INTEGER  NOT NULL  DEFAULT 0,
  ship       INTEGER  NOT NULL  DEFAULT 0,
  ball       INTEGER  NOT NULL  DEFAULT 0,
  ufo        INTEGER  NOT NULL  DEFAULT 0,
  wave       INTEGER  NOT NULL  DEFAULT 0,
  robot      INTEGER  NOT NULL  DEFAULT 0,
  spider     INTEGER  NOT NULL  DEFAULT 0,
  explosion  INTEGER  NOT NULL  DEFAULT 0,
  special    INTEGER  NOT NULL  DEFAULT 0,
  glow       INTEGER  NOT NULL  DEFAULT 0,

  created_at   TEXT    NOT NULL  DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'now')),
  last_played  TEXT    NOT NULL  DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'now')),

  is_banned         INTEGER  NOT NULL  DEFAULT 0,
  is_banned_upload  INTEGER  NOT NULL  DEFAULT 0
);

-- +migrate down
DROP TABLE users;