# Jservice

A fork of [sottenad/jService](https://github.com/sottenad/jService) used for educational, non-profit purposes

## Required files
```
secrets/db_password.txt
```

## Run
- Clone the repo
- Run `docker compose up`

## Load the database with data
```sh
bundle exec rake get_clues[1,2]
```
- Or use the `restore-db.sh` script if you already have a database backup file that you want to restore

## Update Ruby and Rails versions
- See outdated dependencies: `docker exec jservice bundle outdated`
- Update the Ruby version used in `Dockerfile.dev`
- Update the Ruby and Rails versions used in `Gemfile`
- Remove `Gemfile.lock` from the repo
- Update the `COPY` command in `Dockerfile.dev` (remove `Gemfile.lock` from it):
  ```
  COPY Gemfile ./
  ```
- Remove the `jservice` container, `jservice` image and `jservice-bundle` volume from the host
- Rebuild the image: `docker compose build --no-cache`
- Run `docker compose run jservice bundle install` to also have the expected Gemfile.lock in our host
- Adjust the code as needed, follow the release notes and migration guides
- Run `docker compose up` and make sure everything works as expected
- Revert the `Dockerfile.dev` change back to:
  ```
  COPY Gemfile Gemfile.lock ./
  ```
- Update the Ruby version used in `Dockerfile` to match the one we migrated to earlier (for production image)
- Commit & Push
- Deploy to staging server and test, then to prod server