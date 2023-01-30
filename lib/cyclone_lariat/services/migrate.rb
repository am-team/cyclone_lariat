# frozen_string_literal: true

module CycloneLariat
  module Services
    class Migrate
      attr_reader :repo, :dir

      def initialize(repo:, dir:)
        @repo = repo
        @dir = dir
      end

      def call
        alert('No one migration exists') if !Dir.exist?(dir) || Dir.empty?(dir)
        output = []

        migration_paths.each do |path|
          filename = File.basename(path, '.rb')
          version, title = filename.split('_', 2)

          next if existed_migrations.include? version.to_i

          class_name = title.split('_').collect(&:capitalize).join
          output << "Up - #{version} #{class_name} #{path}"
          require_relative Pathname.new(Dir.pwd) + Pathname.new(path)
          Object.const_get(class_name).new.up
          repo.add(version)
        end

        output
      end

      private

      # Sorted by timestamp
      def migration_paths
        # lariat/migrate/1668161620_many_to_one.rb
        Dir.glob("#{dir}/*.rb").sort_by do |file_path|
          # 1668161620_many_to_one.rb
          file_name = file_path.split('/')[-1]
          # 1668161620
          file_name.split('_').first.to_i
        end
      end

      def existed_migrations
        @existed_migrations ||= repo.all.map { |row| row[:version] }
      end
    end
  end
end
