# frozen_string_literal: true

require 'fileutils'
require_relative 'sns_client'
require_relative 'sqs_client'
require 'luna_park/errors'

module CycloneLariat
  class Migration
    attr_reader :sns, :sqs

    DIR = './lariat/migrations'

    def initialize
      @sns = CycloneLariat::SnsClient.new
      @sqs = CycloneLariat::SqsClient.new
    end

    def up
      raise LunaPark::Errors::Abstract, "Up method should be defined in #{self.class.name}"
    end

    def down
      raise LunaPark::Errors::Abstract, "Down method should be defined in #{self.class.name}"
    end

    class << self
      def migrate(dataset: CycloneLariat.versions_dataset, dir: DIR)
        alert('No one migration exists') if !Dir.exists?(dir) || Dir.empty?(dir)

        Dir.glob("#{dir}/*.rb") do |path|
          filename = File.basename(path, '.rb')
          version, title = filename.split('_', 2)

          existed_migrations = dataset.all.map { |row| row[:version] }
          unless existed_migrations.include? version.to_i
            class_name = title.split('_').collect(&:capitalize).join
            puts "Up - #{version} #{class_name} #{path}"
            require_relative Pathname.new(Dir.pwd) + Pathname.new(path)
            Object.const_get(class_name).new.up
            dataset.insert(version: version)
          end
        end
      end

      def rollback(version = nil, dataset: CycloneLariat.versions_dataset, dir: DIR)
        existed_migrations = dataset.all.map { |row| row[:version] }.sort
        version ||= existed_migrations[-1]
        migrations_to_downgrade = existed_migrations.select { |migration| migration >= version }

        paths = []
        migrations_to_downgrade.each do |migration|
          path = Pathname.new(Dir.pwd) + Pathname.new(dir)
          founded = Dir.glob("#{path}/#{migration}_*.rb")
          raise "Could not found migration: `#{migration}` in #{path}" if founded.empty?
          raise "Found lot of migration: `#{migration}` in #{path}"    if founded.size > 1

          paths += founded
        end

        paths.each do |path|
          filename       = File.basename(path, '.rb')
          version, title = filename.split('_', 2)
          class_name     = title.split('_').collect(&:capitalize).join
          puts "Down - #{version} #{class_name} #{path}"
          require_relative Pathname.new(Dir.pwd) + Pathname.new(path)
          Object.const_get(class_name).new.down
          dataset.filter(version: version).delete
        end
      end
    end
  end
end
