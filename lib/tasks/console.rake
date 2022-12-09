# frozen_string_literal: true

desc 'IRB console with required CycloneLariat'
task :console do
  # require 'cyclone_lariat'
  require 'cyclone_lariat'
  require 'irb'
  require_relative '../../config/initializers/cyclone_lariat'
  # require_relative(init_file) if File.exists?(init_file)

  ARGV.clear
  IRB.start
end
