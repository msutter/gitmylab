module Gitmylab
  module Utils

    class Config

      @@local_config_path   = Pathname.new(File.join(ENV['HOME'], ".gitmylab"))

      @@access_project      = nil
      @@remote_config_path  = nil

      @@config_example_path = Pathname.new(File.join(LIB_PATH, "..", "config"))

      @@local_config_files  = [
        'gitlab.yaml',
        'sync.yaml',
        'ad.yaml',
        'access.yaml',
        'exclude.yaml',
        'include.yaml'
      ]

      @@remote_config_files = [
        'users.yaml',
        'roles.yaml'
      ]

      def self.setup(command)
        begin
          create_local_config_files
          load_local_config_files

          # setup and connect
          gitlab_setup

          if command == :access
            access_setup
           # ad setup
            ad_setup if configatron.access.map_to_active_directory
          end

        rescue => e
          puts e.inspect
          puts e.backtrace
          exit 1
        end

      end

      def self.access_setup
        if configatron.access.has_key?(:access_config_files_project)
          sync_access_repo
          location = Pathname.new(File.join(configatron.sync.gitlab_root_path, access_project.path_with_group))
        else
          location = @@local_config_path
        end

        @@remote_config_files.each do |file|
          config_file_path = location.join(file)
          raise "missing config file #{file} in repository #{access_project.web_url}" unless File.exists?(config_file_path)
          load_config_file(config_file_path)
        end

      end

      def self.gitlab_setup
        # apply gitlab config
        ::Gitlab.configure do |config|
          config.endpoint       = configatron.gitlab.endpoint
          config.private_token  = configatron.gitlab.private_token
        end
        # test connection
        begin
          ::Gitlab.user
        rescue => e
          raise "Gitlab connection error: #{e}"
        end
      end


      def self.ad_setup
        # apply active directory config
        ActiveDirectory::Base.setup(configatron.ad.to_hash)

        begin
          Timeout::timeout(2) do
            ActiveDirectory::Base.connected?
          end
        rescue Timeout::Error => e
          puts "Active directory connection timeout !"
        rescue
          raise "Active directory connection error: #{ActiveDirectory::Base.error}"
        end

      end

      def self.create_local_config_files
        # create config files in $HOME/.gitmylab
        FileUtils::mkdir_p @@local_config_path unless File.exists?(@@local_config_path)

        @@local_config_files.each do |file|
          create_config_file(file)
        end

        # create remote config files locally if no access repo specified
        @@remote_config_files.each do |file|
          create_config_file(file)
        end unless configatron.access.has_key?(:access_config_files_project)
      end


      def self.create_config_file(file)
        FileUtils.cp(File.join(@@config_example_path, "#{file}.example"), File.join(@@local_config_path, file)) unless File.exists?(File.join(@@local_config_path, file))
      end

      def self.load_local_config_files
        @@local_config_files.each do |file|
          load_config_file(@@local_config_path.join(file))
        end
      end

      def self.load_config_file(file_path)
        group = file_path.basename.sub(/\.yaml/, '').to_s
        configatron.configure_from_hash(group => YAML::load_file(file_path))
      end


      def self.sync_access_repo
        Gitlab::Project.sync({:projects_include => [access_project.path]})
      end

      def self.access_project
        @@access_project ||= Gitlab::Project.find_by_path(configatron.access.access_config_files_project).first
      end

    end

  end
end
