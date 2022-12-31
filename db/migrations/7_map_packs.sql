-- +migrate up
CREATE TABLE map_packs (
  id  SERIAL  PRIMARY KEY,
  
  name        TEXT     NOT NULL,
  stars       INTEGER  NOT NULL,
  coins       INTEGER  NOT NULL,
  difficulty  INTEGER  NOT NULL,

  col1        TEXT     NOT NULL, -- comma separated integers
  col2        TEXT
);

CREATE TABLE map_pack_links (
  idx         INTEGER  NOT NULL  DEFAULT 0, -- solely for ordering purposes
  mappack_id  INTEGER  NOT NULL  REFERENCES map_packs(id),
  level_id    INTEGER  NOT NULL  REFERENCES levels(id)
);

-- +migrate down
DROP TABLE map_packs;