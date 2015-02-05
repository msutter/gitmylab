module Gitmylab
  module Cli

    class Project < Thor

      include Helpers

      class_option  :config_file,
        :aliases => '-c',
        :type    => :boolean,
        :desc    => 'Apply to projects defined in the include/exclude config files'

      desc "sync", "syncronize gitlab repository"
      def sync
        options_check(shell, command, options)
        m = Gitmylab::Manager.new(command, __method__)
        m.project(options)
      end

    end

  end

end
