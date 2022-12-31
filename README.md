# crystal-gauntlet

among balls

## build

`shards build`

you may need to head into `lib/` to fix deps. i'm Very sorry

## setup

copy `.env.example` to `.env` and fill it out, same for `config.toml.example` -> `config.toml`

run `cake db:migrate` (must have [cake](https://github.com/axvm/cake/))

**schemas are highly unstable so you will be offered 0 support in migrating databases for now**, however in the future you'll want to run this each time you update

then `bin/crystal-gauntlet` (or `shards run`)

### real

![real](docs/crystal-gauntlet.jpg)