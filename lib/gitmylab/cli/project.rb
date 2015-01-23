module Gitmylab
  module Cli

    class Project < Thor

      include Helpers

      desc "sync", "syncronize gitlab repository"

      def sync

        projects_and_groups_options_check(shell, command, options)

        m = Gitmylab::Manager.new(command)

        Gitmylab::Cli::Message.level = options.verbosity
        m.project_sync(options)
      end

    end

  end

end
