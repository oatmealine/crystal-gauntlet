-- +migrate up
CREATE TABLE daily_queue (
  level_id  INTEGER  NOT NULL  references levels(id),
  idx       SERIAL   NOT NULL  PRIMARY KEY
);

CREATE TABLE daily_levels (
  level_id    INTEGER  NOT NULL  references levels(id),
  idx         SERIAL   NOT NULL  PRIMARY KEY,
  expires_at  TEXT     NOT NULL
);

CREATE TABLE weekly_queue (
  level_id  INTEGER  NOT NULL  references levels(id),
  idx       SERIAL   NOT NULL  PRIMARY KEY
);

CREATE TABLE weekly_levels (
  level_id    INTEGER  NOT NULL  references levels(id),
  idx         SERIAL   NOT NULL  PRIMARY KEY,
  expires_at  TEXT     NOT NULL
);

-- +migrate down
DROP TABLE daily_queue;
DROP TABLE daily_levels;
DROP TABLE weekly_queue;
DROP TABLE weekly_levels;