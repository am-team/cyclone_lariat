# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.8] - 2022-09-05
Added
- Added configuration options see README.md

## [0.3.8] - 2022-09-05
Changed
- Added pagination to sns topics list for receiving all topics
- Added list topics store for reduce unnecessary requests to aws

## [0.3.7] - 2022-02-10
Changed
- Add exception when received broken JSON

## [0.3.6] - 2022-02-09
Changed
- Downgrade minimum ruby version to 2.4.0

## [0.3.3] - 2021-07-14
Changed
- Bugfix of message equality check

## [0.3.2] - 2021-06-11
Changed
- Bugfix

## [0.3.1] - 2021-06-11
Changed
- Command
- SqsClient

## [0.3.0] - 2021-06-09
Added
- Command
- SqsClient

Changed:
- Client renamed to SnsClient
- `to:` renamed to `topic:`

## [0.2.3] - 2021-06-09
Added
- Skip on empty message with error notify

## [0.2.2] - 2021-06-08
Changed
- Fix save to database
- Rename error to client error

## [0.2.1] - 2021-06-02
- Fix can load from database if error_details is nil

## [0.2.0] - 2021-06-02
Added
- Complete tests
- Production ready

## [0.1.0] - 2021-05-24
- Init project
