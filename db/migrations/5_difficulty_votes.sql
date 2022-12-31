-- +migrate up
CREATE TABLE difficulty_votes (
  level_id  INTEGER  NOT NULL  references levels(id),
  stars     INTEGER  NOT NULL
);

CREATE TABLE demon_difficulty_votes (
  level_id          INTEGER  NOT NULL  references levels(id),
  demon_difficulty  INTEGER  NOT NULL
);

-- +migrate down
DROP TABLE difficulty_votes;
DROP TABLE demon_difficulty_votes;