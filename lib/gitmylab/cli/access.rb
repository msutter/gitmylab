module Gitmylab
  module Cli

    class Access < Thor

      include Helpers

      class_option :groups,
        :aliases => '-g',
        :type    => :array,
        :desc    => 'Apply to given groups.'

      class_option :all_groups,
        :aliases => '-A',
        :type    => :boolean,
        :desc    => 'Apply to all groups'


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
        m = Gitmylab::Manager.new(command, __method__, options)
        m.access
      end

      desc "remove", "Remove gitlab access"
      option :users,
        :aliases  => '-u',
        :type     => :array,
        :desc     => 'The name of the users. This is the email address user part (the string before the "@")',
        :required => true

      def remove
        options_check(shell, command, options)
        m = Gitmylab::Manager.new(command, __method__, options)
        m.access
      end

      desc "list", "List gitlab access"
      option :users,
        :aliases  => '-u',
        :type     => :array,
        :desc     => 'The name of the users. This is the email address user part (the string before the "@")'

      option :dump_config_file,
        :aliases  => '-d',
        :type     => :boolean,
        :desc     => 'Generate the access config file based on current accesses'

      def list
        options_check(shell, command, options)
        m = Gitmylab::Manager.new(command, __method__, options)
        m.access
      end

      desc "sync", "Sync gitlab access based on the roles config file"

      option :deletion,
        :aliases => '-d',
        :type    => :boolean,
        :desc    => "By default, the existing accesses will not be deleted. \
Use this option to delete the accesses absent from roles config file",
        :default => false

      option :force_deletion,
        :aliases => '-f',
        :type    => :boolean,
        :desc    => "By default, the deletion of existing accesses will aks if you're sure to execute a destructive action. \
Use this option to force the deletion without confirmation",
        :default => false

      option :regression,
        :aliases => '-R',
        :type    => :boolean,
        :desc    => "By default, the existing accesses will not be regressed. Use this option to regress the access",
        :default => false

      def sync
        if options['deletion']
          confirm = options['force_deletion'] ? 'YES' : ask(
            "This will DELETE all projects and groups permissions not defined in your role config file.\n\
You can use the --force-deletion option to bypass the confirmation message.\n\
Are you sure ?",
            :limited_to => ['YES', 'NO']
          )
          exit 1 if (confirm != 'YES')
        end

        options_help unless options.any?
        m = Gitmylab::Manager.new(command, __method__, options)
        m.access
      end

      desc "clean", "Clean duplicated gitlab accesses."

      def clean
        options_check(shell, command, options)
        m = Gitmylab::Manager.new(command, __method__, options, shell)
        m.access
      end


    end

  end

end
