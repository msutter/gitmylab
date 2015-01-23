module Gitmylab
  module Cli

    class Access < Thor

      include Helpers

      desc "add", "Add gitlab access"
      def add
        projects_and_groups_options_check(shell, command, options)
        m = Gitmylab::Manager.new(command)
        m.access_add(options)
      end

      desc "remove", "Remove gitlab access"
      def remove
        projects_and_groups_options_check(shell, command, options)
        m = Gitmylab::Manager.new(command)
        m.access_remove(options)
      end

    end

  end

end
