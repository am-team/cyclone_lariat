# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :lariat_versions do
      Integer :version, null: false, unique: true
    end
  end
end
