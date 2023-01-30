# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :async_messages do
      column   :uuid, :uuid, primary_key: true
      String   :kind,                        null: false
      String   :type,                        null: false
      Integer  :version,                     null: false
      String   :publisher,                   null: false
      column   :data, :json,                 null: false
      String   :client_error_message,        null: true,  default: nil
      column   :client_error_details, :json, null: true,  default: nil
      DateTime :sent_at,                     null: true,  default: nil
      DateTime :received_at,                 null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :processed_at,                null: true,  default: nil
    end
  end
end
