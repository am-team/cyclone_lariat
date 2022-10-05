# frozen_string_literal: true

require 'rake'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

# tasks from lib directory
Rake.add_rakelib 'lib/tasks'

task default: %i[spec]
