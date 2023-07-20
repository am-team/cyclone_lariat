# frozen_string_literal: true

module CycloneLariat
  module Services
    class Rollback
      attr_reader :repo, :dir

      def initialize(repo:, dir:)
        @repo = repo
        @dir = dir
      end

      def call(version = nil)
        return 'No migration exists' if !Dir.exist?(dir) || Dir.empty?(dir)

        version ||= existed_migrations[-1]
        output = []

        paths_of_downgrades(version).each do |path|
          filename       = File.basename(path, '.rb')
          version, title = filename.split('_', 2)
          class_name     = title.split('_').collect(&:capitalize).join
          output << "Down - #{version} #{class_name} #{path}"
          require_relative Pathname.new(Dir.pwd) + Pathname.new(path)
          Object.const_get(class_name).new.down
          repo.remove(version)
        end

        output
      end

      def existed_migrations
        @existed_migrations ||= repo.all.map { |row| row[:version] }.sort
      end

      def paths_of_downgrades(version)
        migrations_to_downgrade = existed_migrations.select { |migration| migration >= version }

        paths = []
        migrations_to_downgrade.each do |migration|
          path = Pathname.new(Dir.pwd) + Pathname.new(dir)
          founded = Dir.glob("#{path}/#{migration}_*.rb")
          raise "Could not found migration: `#{migration}` in #{path}" if founded.empty?
          raise "Found lot of migration: `#{migration}` in #{path}"    if founded.size > 1

          paths += founded
        end

        paths
      end
    end
  end
end
