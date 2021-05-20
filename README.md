# Cyclone lariat

This is gem work like middleware for [shrunken](https://github.com/ruby-shoryuken/shoryuken). It save all events to database. And catch and produce all exceptions.  

![Luna Park](docs/_imgs/lariat.jpg)


## Client

You can use client directly

```ruby
client = CycloneLariat::Client.new(
  key: APP_CONF.aws.key,
  secret_key: APP_CONF.aws.secret_key,
  region: APP_CONF.aws.region,
  version: 1,
  publisher: 'pilot'
)

client.publish_event 'test',
                     data: { foo: 1 },
                     to: APP_CONF.aws.fanout
```

Or you can use client as Repo.

```ruby
class YourClient < CycloneLariat::Client
  version 1
  publisher 'pilot'
  
  def test
    publish event('test', data: { foo: 1 }), to: APP_CONF.aws.fanout
  end
end

client = YourClient.new(
  key: APP_CONF.aws.key,
  secret_key: APP_CONF.aws.secret_key,
  region: APP_CONF.aws.region
)

client.test
```

# Middleware
If you use middleware:
- Store all events to dataset
- Notify every input sqs message
- Notify every error 

```ruby

class Receiver
  include Shoryuken::Worker
  
  DB = Sequel.connect(host: 'localhost', user: 'ruby')

  shoryuken_options auto_delete: true,
                    body_parser: ->(sqs_msg) {
                      JSON.parse(sqs_msg.body, symbolize_names: true)
                    },
                    queue: 'your_sqs_queue_name'

  server_middleware do |chain|
    chain.add CycloneLariat::Middleware,
              dataset: DB[:events],
              errors_notifier: LunaPark::Notifiers::Sentry.new,
              message_notifier: LunaPark::Notifiers::Log.new(min_lvl: :debug, format: :pretty_json)
    # If you don`t need to log messages, you can add middleware in this way:
    # chain.add CycloneLariat::Middleware, dataset: DB[:events]
  end

  def perform(_sqs_message, sqs_message_body)
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
    create_table :events do
      column   :uuid, :uuid, primary_key: true
      String   :type,                     null: false
      String   :publisher,                null: false
      column   :data, :json,              null: false
      Integer  :version,                  null: false
      DateTime :sent_at,                  null: true,  default: nil
      DateTime :received_at,              null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :processed_at,             null: false, default: Sequel::CURRENT_TIMESTAMP
    end
  end
end
```



