# Cyclone lariat

This is gem work like middleware for [shoryuken](https://github.com/ruby-shoryuken/shoryuken). It save all events to database. And catch and produce all exceptions.  

![Luna Park](docs/_imgs/lariat.jpg)


```ruby
# Gemfile
gem 'cyclone_lariat', require: false
```


## Client

You can use client directly

```ruby
require 'cyclone_lariat/client'

client = CycloneLariat::Client.new(
  key:        APP_CONF.aws.key,
  secret_key: APP_CONF.aws.secret_key,
  region:     APP_CONF.aws.region,
  version:    1,                          # at default 1
  publisher:  'pilot',
  instance:   INSTANCE                    # at default :prod
)
```

You can don't define topic, and it's name will be defined automatically 
```ruby
                     # event_type        data                                    topic
client.publish_event 'email_is_created', data: { mail: 'john.doe@example.com' } # prod-event-fanout-pilot-email_is_created
client.publish_event 'email_is_removed', data: { mail: 'john.doe@example.com' } # prod-event-fanout-pilot-email_is_removed
```
Or you can define it by handle. For example, if you want to send different events to same channel.
```ruby
                     # event_type        data                                    topic
client.publish_event 'email_is_created', data: { mail: 'john.doe@example.com' }, to: 'prod-event-fanout-pilot-emails'
client.publish_event 'email_is_removed', data: { mail: 'john.doe@example.com' }, to: 'prod-event-fanout-pilot-emails'
```

Or you can use client as Repo.

```ruby
require 'cyclone_lariat/client'

class YourClient < CycloneLariat::Client
  version   1
  publisher 'pilot'
  instance  'stage'
  
  def email_is_created(mail)
    publish event( 'email_is_created', 
      data: { mail: mail }
    ), 
    to: APP_CONF.aws.fanout.emails
  end
  
  def email_is_removed(mail)
    publish event( 'email_is_removed', 
      data: { mail: mail }
    ), 
    to: APP_CONF.aws.fanout.email
  end
end

# Init repo
client = YourClient.new(key: APP_CONF.aws.key, secret_key: APP_CONF.aws.secret_key, region: APP_CONF.aws.region)

# And send topics
client.email_is_created 'john.doe@example.com'
client.email_is_removed 'john.doe@example.com'
```

# Middleware
If you use middleware:
- Store all events to dataset
- Notify every input sqs message
- Notify every error 

```ruby
require 'cyclone_lariat/middleware'

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
    # If you dont define dataset - middleware does store events in db
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
    create_table :events do
      column   :uuid, :uuid, primary_key: true
      String   :type,                     null: false
      Integer  :version,                  null: false
      String   :publisher,                null: false
      column   :data, :json,              null: false
      String   :error_message,            null: true,  default: nil
      column   :error_details, :json,     null: true,  default: nil
      DateTime :sent_at,                  null: true,  default: nil
      DateTime :received_at,              null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :processed_at,             null: true,  default: nil
    end
  end
end
```



