module Gitmylab
  module Cli

    class Project < Thor

      include Helpers

      desc "sync", "syncronize gitlab repository"

      def sync
        options_check(shell, command, options)
        m = Gitmylab::Manager.new(command, __method__)
        m.project(options)
      end

    end

  end

end
