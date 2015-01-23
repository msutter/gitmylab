module Gitmylab
  module Cli

    class Branch < Thor

      include Helpers

      desc "add", "Add a branch to gitlab projects"
      def add
        projects_and_groups_options_check(shell, command, options)
        m = Gitmylab::Manager.new(command)
        m.branch_add(options)
      end

      desc "protect", "Protect a branch of gitlab projects"
      def protect
        projects_and_groups_options_check(shell, command, options)
        m = Gitmylab::Manager.new(command)
        m.branch_protect(options)
      end

      desc "unprotect", "Unprotect a branch of gitlab projects"
      def unprotect
        projects_and_groups_options_check(shell, command, options)
        m = Gitmylab::Manager.new(command)
        m.branch_unprotect(options)
      end

    end

  end

end
