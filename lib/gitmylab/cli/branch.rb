module Gitmylab
  module Cli

    class Branch < Thor

      include Helpers

      desc "list", "List branches to gitlab projects"
      def list
        options_check(shell, command, options)
        m = Gitmylab::Manager.new(command, __method__)
        m.branch_list(options)
      end

      desc "add", "Add a branch to gitlab projects"

      option :name,
        :aliases  => '-n',
        :type     => :string,
        :desc     => 'The name of the new branch',
        :required => true

      option :ref,
        :aliases => '-r',
        :type    => :string,
        :desc    => 'Create branch from commit sha or existing branch',
        :default => 'master'

      option :protected,
        :aliases => '-P',
        :type    => :boolean,
        :desc    => 'By default, the new branch will be unprotected. Use this option to protect the new branch',
        :default => false


      def add
        options_check(shell, command, options)
        m = Gitmylab::Manager.new(command, __method__)
        m.branch_add(options)
      end

      desc "protect", "Protect a branch of gitlab projects"
      option :name,
        :aliases  => '-n',
        :type     => :string,
        :desc     => 'The name of the branch',
        :required => true
      def protect
        options_check(shell, command, options)
        m = Gitmylab::Manager.new(command, __method__)
        m.branch_protect(options)
      end

      desc "unprotect", "Unprotect a branch of gitlab projects"
      option :name,
        :aliases  => '-n',
        :type     => :string,
        :desc     => 'The name of the branch',
        :required => true
      def unprotect
        options_check(shell, command, options)
        m = Gitmylab::Manager.new(command, __method__)
        m.branch_unprotect(options)
      end

    end

  end

end
