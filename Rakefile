# frozen_string_literal: true

require 'rake'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

# tasks from lib directory
Dir[File.expand_path('lib/tasks/**/*.rake', __dir__)].each do |entity|
  print "#{entity} : "
  puts load entity
end

task default: %i[spec] # rubocop]
