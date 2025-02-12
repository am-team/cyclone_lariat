# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cyclone_lariat/version'

Gem::Specification.new do |spec|
  spec.name          = 'cyclone_lariat'
  spec.version       = CycloneLariat::VERSION
  spec.authors       = ['Alexander Kudrin', 'Philip Sorokin', 'Kirill Drozdov', 'Vitaly Perminov']
  spec.email         = ['kudrin.alexander@gmail.com']

  spec.summary       = 'Shoryuken middleware for LunaPark based application.'
  spec.homepage      = 'https://am-team.github.io/cyclone_lariat/#/'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.3'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    # spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
          'public gem pushes.'
  end
  spec.metadata['yard.run'] = 'yri'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|docs|examples|config)/}) }
  end

  spec.require_paths = ['lib']
  spec.bindir = 'bin'
  spec.executables = ['cyclone_lariat']

  spec.add_dependency 'aws-sdk-sns'
  spec.add_dependency 'aws-sdk-sqs'
  spec.add_dependency 'dry-cli', '~> 0.6'
  spec.add_dependency 'dry-validation', '< 1.9.0' # 1.9.0 use zeitwerk that require ruby > 2.5
  spec.add_dependency 'luna_park', '~> 0.11'
  spec.add_dependency 'terminal-table', '~> 3.0'

  # Add dependencies for libraries that are being removed from the Ruby standard library
  spec.add_dependency 'base64', '~> 0.1.0'
  spec.add_dependency 'bigdecimal', '~> 3.1'
  spec.add_dependency 'logger', '~> 1.6'
  spec.add_dependency 'mutex_m', '~> 0.1.0'
  spec.add_dependency 'ostruct', '~> 0.5.0'

  spec.add_development_dependency 'activerecord', '~> 6.1'
  spec.add_development_dependency 'bundler', '~> 2.1'
  spec.add_development_dependency 'byebug', '~> 11.1'
  spec.add_development_dependency 'database_cleaner-active_record'
  spec.add_development_dependency 'database_cleaner-sequel', '~> 2.0'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-bundler'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'guard-rubocop'
  spec.add_development_dependency 'pg', '~> 1.5'
  spec.add_development_dependency 'pry', '~> 0.14.2'
  spec.add_development_dependency 'pry-byebug', '~> 3.9'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.10'
  spec.add_development_dependency 'rubocop', '~> 1.50'
  spec.add_development_dependency 'rubocop-performance', '~> 1.17'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.18'
  spec.add_development_dependency 'simplecov', '~> 0.18'
  spec.add_development_dependency 'timecop', '~> 0.9'
  spec.add_development_dependency 'webmock', '~> 3.7.0'
  spec.add_development_dependency 'yard', '~> 0.9'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
