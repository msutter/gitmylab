module Gitmylab
  module Cli

    class Access < Thor

      include Helpers

      desc "add", "Add gitlab access"
      option :user,
        :aliases  => '-u',
        :type     => :string,
        :desc     => 'The name of the user. This is the email address user part (the string before the "@")',
        :required => true

      option :level,
        :aliases  => '-l',
        :type     => :string,
        :desc     => 'The permission level',
        :enum     => ['owner', 'master', 'developer', 'reporter', 'guest'],
        :required => true

      option :regression,
        :aliases => '-R',
        :type    => :boolean,
        :desc    => 'By default, the existing accesses will not be regressed. Use this option to regress the access',
        :default => false

      def add
        projects_and_groups_options_check(shell, command, options)
        m = Gitmylab::Manager.new(command, __method__)
        m.access_add(options)
      end

      desc "remove", "Remove gitlab access"
      def remove
        projects_and_groups_options_check(shell, command, options)
        m = Gitmylab::Manager.new(command, __method__)
        m.access_remove(options)
      end

    end

  end

end
