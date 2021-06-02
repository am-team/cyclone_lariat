# frozen_string_literal: true

require 'rake'

# tasks from lib directory
Dir[File.expand_path('lib/tasks/**/*.rake', __dir__)].each do |entity|
  puts entity
  load entity
end

task default: %i[spec] # rubocop]
