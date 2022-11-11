# Cyclone lariat

This gem work in few scenarios:
- like middleware for [shoryuken](https://github.com/ruby-shoryuken/shoryuken). It save all events to database. And catch and produce all exceptions.  
- like middleware it can record all incoming messages
- like client which can send message to SNS topics and SQS queues
- also it can hep you with CI\CD to manage topics, queues and subscription like database migration 

![Cyclone lariat](docs/_imgs/lariat.jpg)


# Client / Publisher
At first lets understand what the difference between SQS and SNS:  
- Amazon Simple Queue Service (SQS) lets you send, store, and receive messages between software components at any volume, without losing messages or requiring other services to be available.
- Amazon Simple Notification Service (SNS) sends notifications two ways Application2Person (like send sms).
And the second way is Application2Application, that's way more important for us. In this way you case use
SNS service like fanout.

![SQS/SNS](docs/_imgs/sqs_sns_diagram.png)

For use **cyclone_lariat** as _Publisher_ lets make install CycloneLariat. 

## Install cyclone_lariat
Edit Gemfile:
```ruby
# Gemfile
gem 'sequel'
gem 'cyclone_lariat'
```
And run in console:
```bash
$ bundle install
$ cyclone_lariat install
```

Last command will create 2 files:
- ./lib/tasks/cyclone_lariat.rake - Rake tasks, for management migrations
- ./config/initializers/cyclone_lariat.rb - Configuration default values for cyclone lariat usage

## Configuration
```ruby
# frozen_string_literal: true

CycloneLariat.tap do |cl|
  cl.default_version    = 1                       # api version
  cl.aws_key            = ENV['AWS_KEY']          # aws key
  cl.aws_account_id     = ENV['AWS_ACCOUNT_ID']   # aws account id
  cl.aws_secret_key     = ENV['AWS_SECRET_KEY']   # aws secret
  cl.aws_default_region = ENV['AWS_REGION']       # aws default region
  cl.publisher          = ENV['APP_NAME']         # name of your publishers, usually name of your application 
  cl.default_instance   = ENV['INSTANCE']         # stage, production, test
  cl.events_dataset     = DB[:events]             # sequel dataset for store income messages, for receiver
  cl.versions_dataset   = DB[:lariat_versions]    # sequel dataset for migrations, for publisher
end
```
If you are only using your application as a publisher, you may not need to set the events_dataset
parameter.

Before creating the first migration, let's explain what `CycloneLariat::Message` is.

## Messages
Message in Amazon SQS\SNS service it's a 
[object](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-message-metadata.html#sqs-message-attributes)
that has several attributes. The main attributes are the **body**, which consists of the published 
data. The body is a _String_, but we can use it as a _JSON_ object. **Cyclone_lariat** use this scheme:

```json
{
  "uuid": "f2ce3813-0905-4d81-a60e-f289f2431f50",       // Uniq message identificator
  "publisher": "sample_app",                            // Publisher application name
  "request_id": "51285005-8a06-4181-b5fd-bf29f3b1a45a", // Optional: X-Request-Id 
  "type": "event_note_created",                         // Type of Event or Command
  "version": 1,                                         // Version of data structure
  "data": {
    "id": 12,
    "text": "Sample of published data",
    "attributes": ["one", "two", "three"]       
  },
  "sent_at": "2022-11-09T11:42:18.203+01:00"      // Time when message was sended in ISO8601 Standard
}
```

Idea about X-Request-Id you can see at [StackOverflow](https://stackoverflow.com/questions/25433258/what-is-the-x-request-id-http-header).

As you see, type has prefix 'event_' in cyclone lariat you has two kinds of messages - _Event_ and _Command_. 

### Command vs Event
Commands and events are both simple domain structures that contain solely data for reading. That means
they contain no behaviour or business logic.

A command is an object that is sent to the domain for a state change which is handled by a command
handler. They should be named with a verb in an imperative mood plus the aggregate name which it 
operates on. Such request can be rejected due to the data the command holds being invalid/inconsistent.
There should be exactly 1 handler for each command. Once the command has been executed, the consumer 
can then carry out whatever the task is depending on the output of the command.

An event is a statement of fact about what change has been made to the domain state. They are named 
with the aggregate name where the change took place plus the verb past-participle. An event happens off
the back of a command. 
A command can emit any number of events. The sender of the event does not care who receives it or 
whether it has been received at all.

### Publish
For publishing _Event_ or _Commands_, you have two ways, send _Message_ directly:

```ruby
CycloneLariat.tap do |cl|
  # Config app here
end

client = CycloneLariat::SnsClient.new(instance: 'auth', version: 2)

client.publish_command('register_user', data: {
    first_name: 'John', 
    last_name: 'Doe', 
    mail: 'john.doe@example.com' 
  }, fifo: false 
)
```

That's call, will generate message body: 
```json
{
  "uuid": "f2ce3813-0905-4d81-a60e-f289f2431f50",
  "publisher": "auth",
  "type": "command_register_user",
  "version": 2,
  "data": {
    "first_name": "John", 
    "last_name": "Doe", 
    "mail": "john.doe@example.com"      
  },
  "sent_at": "2022-11-09T11:42:18.203+01:00"      // Time when message was sended in ISO8601 Standard
}
```

Or better way is make custom client, as [Repository](https://deviq.com/design-patterns/repository-pattern) pattern.

```ruby
require 'cyclone_lariat/sns_client' # If require: false in Gemfile

class YourClient < CycloneLariat::SnsClient
  version 1
  publisher 'pilot'
  instance 'stage'

  def email_is_created(mail)
    publish event('email_is_created', data: { mail: mail }), fifo: true
  end

  def email_is_removed(mail)
    publish event('email_is_removed', data: { mail: mail }), fifo: true
  end


  def delete_user(mail)
    publish command('delete_user', data: { mail: mail }), fifo: false
  end
end

# Init repo
client = YourClient.new

# And send topics
client.email_is_created 'john.doe@example.com'
client.email_is_removed 'john.doe@example.com'
client.delete_user      'john.doe@example.com'
```

### Topics and Queue
An Amazon SNS topic and SQS queue is a logical access point that acts as a communication channel. Both 
of them has specific address ARN.

```
# Topic example
arn:aws:sns:eu-west-1:247602342345:test-event-fanout-cyclone_lariat-note_added.fifo

# Queue example
arn:aws:sqs:eu-west-1:247602342345:test-event-queue-cyclone_lariat-note_added-notifier.fifo
```

Split ARN:
- `arn:aws:sns`  - Prefix for SNS Topics
- `arn:aws:sqs`  - Prefix for SQS Queues
- `eu-west-1`    - [AWS Region](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#concepts-regions)
- `247602342345` - [AWS account](https://docs.aws.amazon.com/IAM/latest/UserGuide/console_account-alias.html)
- `test-event-fanout-cyclone_lariat-note_added` - Topic \ Queue name
- `.fifo` - if Topic or queue is [FIFO](https://aws.amazon.com/blogs/aws/introducing-amazon-sns-fifo-first-in-first-out-pub-sub-messaging/), they must has that suffix. 

Region and client_id usually set using the **cyclone_lariat** [configuration](#Configuration).

## Declaration for topic and queues name
In **cyclone_lariat** we have a declaration for defining topic and queues names. 
This can help with organizing order.

```ruby
CycloneLariat.tap do |cfg|
  cfg.instance  = 'test'
  cfg.publisher = 'cyclone_lariat'
  # ...
end

CycloneLariat::SnsClient.new.publish_command('register_user', data: {
    first_name: 'John', 
    last_name: 'Doe', 
    mail: 'john.doe@example.com' 
  }, fifo: true 
)

# or in repository-like style: 

class YourClient < CycloneLariat::SnsClient
  def register_user(first:, last:, mail:)
    publish command('register_user', data: { mail: mail }), fifo: true
  end
end
```


Will publish message on this topic: `test-command-fanout-cyclone_lariat-register_user`.

Split topic name:
- `test` - instance;
- `command` - kind - [event or command](#command-vs-event);
- `fanount` - resource type - fanout for SNS topics; 
- `cyclone_lariat` - publisher name;
- `regiser_user` - message type.

For queues you also can define destination.
```ruby
CycloneLariat::SqsClient.new.publish_event(
  'register_user', data: { mail: 'john.doe@example.com' }, 
                   dest: :mailer, fifo: true
)


# or in repository-like style: 

class YourClient < CycloneLariat::SnsClient
  # ...
  
  def register_user(first:, last:, mail:)
    publish event('register_user', data: { mail: mail }), fifo: true
  end
end
```

Will publish message on queue: `test-event-queue-cyclone_lariat-register_user-mailer`.

Split queue name:
- `test` - instance;
- `event` - kind - [event or command](#command-vs-event);
- `queue` - resource type - queue for SQS;
- `cyclone_lariat` - publisher name;
- `regiser_user` - message type.
- `mailer` - destination

You also can sent message to queue with custom name. But this way does not recommended.

```ruby
# Directly
CycloneLariat::SqsClient.new.publish_event(
  'register_user', data: { mail: 'john.doe@example.com' }, 
                   dest: :mailer, topic: 'custom_topic_name.fifo', fifo: true
)

# Repository
class YourClient < CycloneLariat::SnsClient
  # ...

  def register_user(first:, last:, mail:)
    publish event('register_user', data: { mail: mail }), 
            topic: 'custom_topic_name.fifo', fifo: true
  end
end
```
Will publish message on queue: `custom_topic` with fifo suffix.

# Migrations

With `ciclone_lariat` you can create, delete and subscribe you queues with migration, like database migration. 
For storing versions of **cyclone_lariat** migrations you should create database table. 

```ruby
# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :lariat_versions do
      Integer :version, null: false, unique: true
    end
  end
end
```
After migrate this database migration, create **cyclone_lariat** migration.

```bash
$ cyclone_lariat generate migration user_created
```

That is command should create migration file, lets edit it.

```ruby
# ./lariat/migrate/1668097991_user_created_queue.rb

# frozen_string_literal: true

class UserCreatedQueue < CycloneLariat::Migration
  def up
    create queue(:user_created, dest: :mailer, fifo: true)
  end

  def down
    delete queue(:user_created, dest: :mailer, fifo: true)
  end
end
```

For apply migration use:
```bash
$ rake cyclone_lariat:migrate
```

For decline migration use:
```bash
$ rake cyclone_lariat:rollback
```

Since the SNS\SQS management does not support an ACID transaction (in the sense of a database), 
I highly recommend using the atomic schema:

```ruby
# BAD:
class UserCreated < CycloneLariat::Migration
  def up
    create queue(:user_created, dest: :mailer, fifo: true)
    create topic(:user_created, fifo: true)

    subscribe topic: topic(:user_created, fifo: true),
              endpoint: queue(:user_created, dest: :mailer, fifo: true)
  end

  def down
    unsubscribe topic: topic(:user_created, fifo: true),
                endpoint: queue(:user_created, dest: :mailer, fifo: true)

    delete topic(:user_created, fifo: true)
    delete queue(:user_created, dest: :mailer, fifo: true)
  end
end

# GOOD:
class UserCreatedQueue < CycloneLariat::Migration
  def up
    create queue(:user_created, dest: :mailer, fifo: true)
  end

  def down
    delete queue(:user_created, dest: :mailer, fifo: true)
  end
end

class UserCreatedTopic < CycloneLariat::Migration
  def up
    create topic(:user_created, fifo: true)
  end

  def down
    delete topic(:user_created, fifo: true)
  end
end

class UserCreatedSubscription < CycloneLariat::Migration
  def up
    subscribe topic: topic(:user_created, fifo: true),
              endpoint: queue(:user_created, dest: :mailer, fifo: true)
  end

  def down
    unsubscribe topic: topic(:user_created, fifo: true),
                endpoint: queue(:user_created, dest: :mailer, fifo: true)
  end
end
```


#### Example: one-to-many

The first example is when your registration service create new user. Also you have two services: 
mailer - send welcome email, and statistic service.

```ruby
create topic(:user_created, fifo: true)
create queue(:user_created, dest: :mailer, fifo: true)
create queue(:user_created, dest: :stat, fifo: true)

subscribe topic:    topic(:user_created, fifo: true), 
          endpoint: queue(:user_created, dest: :mailer, fifo: true)


subscribe topic:    topic(:user_created, fifo: true),
          endpoint: queue(:user_created, dest: :statistic, fifo: true)
```
![one2many](docs/_imgs/graphviz_01.png)

#### Example: many-to-one

The first example is when your registration service create new user. Also you have two services: 
mailer - send welcome email, and statistic service.

```ruby
create topic(:user_created, fifo: true)
create queue(:user_created, dest: :mailer, fifo: true)
create queue(:user_created, dest: :stat, fifo: true)

subscribe topic:    topic(:user_created, fifo: true), 
          endpoint: queue(:user_created, dest: :mailer, fifo: true)


subscribe topic:    topic(:user_created, fifo: true),
          endpoint: queue(:user_created, dest: :statistic, fifo: true)
```
![one2many](docs/_imgs/graphviz_01.png)





![diagram](docs/_imgs/diagram.png)

## Configure
```ruby
# 'config/initializers/cyclone_lariat.rb'
CycloneLariat.tap do |cl|
  cl.events_dataset   = DB[:events]
end
```

## SnsClient
You can use client directly

```ruby
require 'cyclone_lariat/sns_client' # If require: false in Gemfile 

client = CycloneLariat::SnsClient.new(
  key: APP_CONF.aws.key,
  secret_key: APP_CONF.aws.secret_key,
  region: APP_CONF.aws.region,
  version: 1, # at default 1
  publisher: 'pilot',
  instance: INSTANCE # at default :prod
)
```

You can don't define topic, and it's name will be defined automatically 
```ruby
                     # event_type        data                                    topic
client.publish_event   'email_is_created', data: { mail: 'john.doe@example.com' } # prod-event-fanout-pilot-email_is_created
client.publish_event   'email_is_removed', data: { mail: 'john.doe@example.com' } # prod-event-fanout-pilot-email_is_removed
client.publish_command 'delete_user',      data: { mail: 'john.doe@example.com' } # prod-command-fanout-pilot-delete_user
```
Or you can define it by handle. For example, if you want to send different events to same channel.
```ruby
                     # event_type        data                                    topic
client.publish_event   'email_is_created', data: { mail: 'john.doe@example.com' }, topic: 'prod-event-fanout-pilot-emails'
client.publish_event   'email_is_removed', data: { mail: 'john.doe@example.com' }, topic: 'prod-event-fanout-pilot-emails'
client.publish_command 'delete_user',      data: { mail: 'john.doe@example.com' }, topic: 'prod-command-fanout-pilot-emails'
```

# SqsClient
SqsClient is really similar to SnsClient. It can be initialized in same way:

```ruby
require 'cyclone_lariat/sns_client' # If require: false in Gemfile 

client = CycloneLariat::SqsClient.new(
  key: APP_CONF.aws.key,
  secret_key: APP_CONF.aws.secret_key,
  region: APP_CONF.aws.region,
  version: 1, # at default 1
  publisher: 'pilot',
  instance: INSTANCE # at default :prod
)
```

As you see all params identity. And you can easily change your sqs-queue to sns-topic when you start work with more
subscribes. But you should define destination.

```ruby
client.publish_event 'email_is_created', data: { mail: 'john.doe@example.com' }, dest: 'notify_service'  
# prod-event-queue-pilot-email_is_created-notify_service
```

Or you can define topic directly:
```ruby
client.publish_event 'email_is_created', data: { mail: 'john.doe@example.com' }, topic: 'prod-event-fanout-pilot-emails'
```

# Migration

Cyclone lariat can create migrations, which can help you create, delete and link new SQS\SNS topics.

At first generate your migration file.

```bash
$ cyclone_lariat generate add_notes_queue
```

It should be created file like that:
```ruby
# frozen_string_literal: true

class AddNotesQueue < CycloneLariat::Migration
  def up
    sns.create_event_topic! :notes
  end

  def down
    sns.delete_event_topic! :notes
  end
end
```

List migration commands:

```ruby
# config/initializers/cyclone_lariat.rb

CycloneLariat.tap do |cl|
  cl.publisher        = 'pet_project' 
  cl.default_instance = 'stage'
  # ...
end
```

```ruby
# SNS raw
sns.create_topic! 'example_topic', fifo: true                                       # example_topic
sns.delete_topic! 'example_topic', fifo: true                                       # example_topic

# SNS events
sns.create_event_topic!   type: 'user_is_created', fifo: true                       # stage-event-fanout-pet_project-user_is_created
sns.delete_event_topic!   type: 'user_is_created'                                   # stage-event-fanout-pet_project-user_is_created

# SNS commands
sns.create_command_topic! type: 'create_new_user', fifo: true                       # stage-command-fanout-pet_project-create_new_use                     r
sns.delete_command_topic! type: 'create_new_user'                                   # stage-command-fanout-pet_project-create_new_user

# SQS raw
sqs.create_queue! 'example_queue', fifo: true                                       # example_queue
sqs.delete_queue! 'example_queue', fifo: true                                       # example_queue

# default type is all - all type of messages can be received 
# default dest is nil - not only one receivers can read messages form this query 
sns.create_event_queue! type: 'user_is_created', dest: 'auth_service', fifo: true   # stage-event-queue-pet_project-user_is_created-auth_service
sns.delete_event_queue! type: 'user_is_created', dest: 'auth_service'               # stage-event-queue-pet_project-user_is_created-auth_service

# SNS commands
# default type is all - all type of messages can be received 
# default dest is nil - not only one receivers can read messages form this query
sns.create_command_queue! type: 'create_new_user', dest: 'auth_service', fifo: true # stage-command-queue-pet_project-create_new_user
sns.delete_command_queue! type: 'create_new_user', dest: 'auth_service'             # stage-command-queue-pet_project-create_new_user

# Link queue to fanout
```

# Middleware
If you use middleware:
- Store all events to dataset
- Notify every input sqs message
- Notify every error 

```ruby
require 'cyclone_lariat/middleware' # If require: false in Gemfile


class Receiver
  include Shoryuken::Worker
  
  DB = Sequel.connect(host: 'localhost', user: 'ruby')

  shoryuken_options auto_delete: true,
                    body_parser: ->(sqs_msg) {
                      JSON.parse(sqs_msg.body, symbolize_names: true)
                    },
                    queue: 'your_sqs_queue_name'

  server_middleware do |chain|
    # Options dataset, errors_notifier and message_notifier is optionals.
    # If you dont define notifiers - middleware does not notify
    # If you dont define dataset - middleware does not store events in db
    chain.add CycloneLariat::Middleware,
              dataset: DB[:events],
              errors_notifier: LunaPark::Notifiers::Sentry.new,
              message_notifier: LunaPark::Notifiers::Log.new(min_lvl: :debug, format: :pretty_json)
  end

  def perform(sqs_message, sqs_message_body)
    # Your logic here
  end
end
```

## Migrations
Before use events storage add and apply this two migrations

```ruby

# First one

Sequel.migration do
  up do
    run <<-SQL
      CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    SQL
  end

  down do
    run <<-SQL
      DROP EXTENSION IF EXISTS "uuid-ossp";
    SQL
  end
end

# The second one:
Sequel.migration do
  change do
    create_table :async_messages do
      column   :uuid, :uuid, primary_key: true
      String   :type,                         null: false
      Integer  :version,                      null: false
      String   :publisher,                    null: false
      column   :data, :json,                  null: false
      String   :client_error_message,         null: true,  default: nil
      column   :client_error_details, :json,  null: true,  default: nil
      DateTime :sent_at,                      null: true,  default: nil
      DateTime :received_at,                  null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :processed_at,                 null: true,  default: nil
    end
  end
end
```

### Rake tasks

For simplify write some Rake tasks you can use CycloneLariat::Repo.

```ruby
# For retry all unprocessed

CycloneLariat.new(DB[:events]).each_unprocessed do |event|
  # Your logic here
end

# For retry all events with client errors

CycloneLariat.new(DB[:events]).each_with_client_errors do |event|
  # Your logic here
end
```
