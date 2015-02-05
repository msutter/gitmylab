module Gitmylab
  module Cli

    class Branch < Thor

      include Helpers

      class_option  :config_file,
        :aliases => '-c',
        :type    => :boolean,
        :desc    => 'Apply to projects defined in the include/exclude config files'


      desc "list", "List branches to gitlab projects"
      def list
        options_check(shell, command, options)
        m = Gitmylab::Manager.new(command, __method__, options)
        m.branch
      end

      desc "add", "Add a branch to gitlab projects"

      option :branch_name,
        :aliases  => '-b',
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
        m = Gitmylab::Manager.new(command, __method__, options)
        m.branch
      end

      desc "protect", "Protect a branch of gitlab projects"

      option :branch_name,
        :aliases  => '-b',
        :type     => :string,
        :desc     => 'The name of the new branch',
        :required => true

      def protect
        options_check(shell, command, options)
        m = Gitmylab::Manager.new(command, __method__, options)
        m.branch
      end

      desc "unprotect", "Unprotect a branch of gitlab projects"

      option :branch_name,
        :aliases  => '-b',
        :type     => :string,
        :desc     => 'The name of the new branch',
        :required => true

      def unprotect
        options_check(shell, command, options)
        m = Gitmylab::Manager.new(command, __method__, options)
        m.branch
      end

    end

  end

end
