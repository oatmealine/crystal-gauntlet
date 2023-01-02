-- +migrate up
CREATE TABLE songs (
  id           SERIAL   PRIMARY KEY,
  url          TEXT     NOT NULL,
  disabled     INTEGER  NOT NULL  DEFAULT 0,
  uploaded_by  INTEGER  references accounts(id)
);

-- song data is fetched on-demand rather than whenever songs are created,
-- so this is a seperate table that's filled in for any given song once
-- it's needed
CREATE TABLE song_data (
  id           SERIAL   PRIMARY KEY references songs(id),

  name       TEXT     NOT NULL,
  author_id  INTEGER  NOT NULL references song_authors(id),

  source    TEXT     NOT NULL  DEFAULT "unknown",
  size      INTEGER, -- in bytes
  duration  INTEGER,

  -- this may contain an absolute url OR a relative one (starts with ./)
  -- depending on if its local or remote
  -- null indicates it should be re-fetched every time its queried
  proxy_url  TEXT,

  last_updated  TEXT  NOT NULL  DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'now'))
);

CREATE TABLE song_authors (
  id          SERIAL  PRIMARY KEY,
  source      TEXT    NOT NULL  DEFAULT "unknown",
  name        TEXT    NOT NULL,
  url         TEXT    NOT NULL
);

INSERT INTO song_authors (id, name, source, url) VALUES (1, "", "unknown", "");

-- +migrate down
DROP TABLE songs;
DROP TABLE song_data;
DROP TABLE song_authors;