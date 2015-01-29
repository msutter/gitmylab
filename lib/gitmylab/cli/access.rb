module Gitmylab
  module Cli

    class Access < Thor

      include Helpers

      class_option :namespaces,
        :aliases => '-n',
        :type    => :array,
        :desc    => 'Apply to given namespaces (groups). This is not the same as [-g], which would apply to projects in the given groups'

      class_option :all_namespaces,
        :aliases => '-A',
        :type    => :boolean,
        :desc    => 'Apply to all namespaces (groups)'

      desc "add", "Add gitlab access"
      option :users,
        :aliases  => '-u',
        :type     => :array,
        :desc     => 'The name of the users. This is the email address user part (the string before the "@")',
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
        :desc    => "By default, the existing accesses will not be regressed. Use this option to regress the access",
        :default => false

      def add
        options_check(shell, command, options)
        m = Gitmylab::Manager.new(command, __method__)
        m.access_add(options)
      end

      desc "remove", "Remove gitlab access"
      option :users,
        :aliases  => '-u',
        :type     => :array,
        :desc     => 'The name of the users. This is the email address user part (the string before the "@")',
        :required => true

      def remove
        options_check(shell, command, options)
        m = Gitmylab::Manager.new(command, __method__)
        m.access_remove(options)
      end

    end

  end

end
