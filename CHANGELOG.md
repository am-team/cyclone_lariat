# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0]
Changed
- Updated method parameters to ensure compatibility with Ruby 3.3

## [1.0.0.rc9]
Changed
- Added message if migration does not exist

## [1.0.0.rc8]
Changed
- Added `before_save` hook to middleware

## [1.0.0.rc7]
Changed
- Fixed `CycloneLariat::Messages::Builder`

## [1.0.0.rc6]
Changed
- Rename `messages_dataset` to `inbox_dataset`
Added
- `CycloneLariat::Outbox` - implementation of the transactional outbox pattern

## [1.0.0.rc5]
Changed
- Update Gemfile.lock

## [1.0.0.rc4]
Added
- `CycloneLariat::Migration#subscribed?(topic:, endpoint:)` to check existance
    subscriptions
Changed
- Fix `CycloneLariat::Clients::Sns#list_subscriptions`

## [1.0.0.rc3]
Added
- `CycloneLariat::Messages::Builder` for building messages

## [1.0.0.rc2]
Changed
- README.md file
Added
- require version file, fixed `bundle exec cyclone_lariat -v`

## [0.4.0]
Changed
- rename `topic` to `queue` for SQS operations, in fact it changed only in methods `publish_event`, `publish_command`
  if you defined custom queue name
- rename client_id to account_id
- send_at no iso8601 format
- A lot of changes, see README.md
Added
- Migrations for create, delete and subscribe topics and queues
- request_id for Event and Command

## [0.3.10] - 2022-10-05
Added
- Added aws_client_od options
Changed:
- Renamed all AWS options with prefix _aws

## [0.3.9] - 2022-10-05 Depricated
Added
- Added configuration options see README.md

## [0.3.8] - 2022-09-05
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
