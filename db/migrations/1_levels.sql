-- +migrate up
CREATE TABLE levels (
  id           SERIAL  PRIMARY KEY,
  created_at   TEXT    NOT NULL  DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'now')),
  modified_at  TEXT    NOT NULL  DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'now')),

  name         TEXT     NOT NULL,
  user_id      INTEGER  NOT NULL  references users(id),
  description  TEXT     NOT NULL  DEFAULT "",
  original     INTEGER,

  game_version    INTEGER  NOT NULL,
  binary_version  INTEGER  NOT NULL,

  password         TEXT,
  requested_stars  INTEGER,
  unlisted         INTEGER  NOT NULL  DEFAULT 0,

  version     INTEGER  NOT NULL  DEFAULT 0,
  level_data  BLOB     NOT NULL,
  extra_data  BLOB     NOT NULL,
  level_info  BLOB     NOT NULL,

  -- checksums, presumably
  wt1         TEXT     NOT NULL,
  wt2         TEXT     NOT NULL,

  song_id  INTEGER  NOT NULL,

  length      INTEGER  NOT NULL,
  objects     INTEGER  NOT NULL,
  coins       INTEGER  NOT NULL  DEFAULT 0,
  has_ldm     INTEGER  NOT NULL  DEFAULT 0,
  two_player  INTEGER  NOT NULL  DEFAULT 0,

  downloads         INTEGER  NOT NULL  DEFAULT 0,
  likes             INTEGER  NOT NULL  DEFAULT 0,
  difficulty        INTEGER,
  demon_difficulty  INTEGER,
  stars             INTEGER,
  featured          INTEGER  NOT NULL  DEFAULT 0,
  epic              INTEGER  NOT NULL  DEFAULT 0,
  rated_coins       INTEGER  NOT NULL  DEFAULT 0
);

-- +migrate down
DROP TABLE levels;