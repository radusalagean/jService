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