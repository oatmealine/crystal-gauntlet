-- +migrate up
CREATE TABLE gauntlets (
  id  SERIAL  PRIMARY KEY
);

CREATE TABLE gauntlet_links (
  idx          INTEGER  NOT NULL  DEFAULT 0, -- solely for ordering purposes
  gauntlet_id  INTEGER  NOT NULL  REFERENCES gauntlets(id),
  level_id     INTEGER  NOT NULL  REFERENCES levels(id)
);

-- +migrate down
DROP TABLE gauntlets;
DROP TABLE gauntlet_links;