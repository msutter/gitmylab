module Gitmylab
  module Cli

    module Helpers

      private

      def options_check(shell, command, options)
        @c  = options[:config_file]
        @d  = options[:dump_config_file]
        @p  = options[:projects_include] ? options[:projects_include].any? : false
        @ap = options[:all_projects]
        @n  = options[:namespaces_include] ? options[:namespaces_include].any? : false
        @g  = options[:groups_include] ? options[:groups_include].any? : false
        @ag = options[:all_groups]
        @u  = options[:users] ? options[:users].any? : false
        @l  = options[:level] ? true : false

        options_help if options_invalid?

      end

      def options_valid?
        true
        # ((@p || @n) ^ @ap ^ @c) || (((@g || @ag) && @u && @l) ^ @c)
        # ((@p || @n || @g) ^ (@ap || @ag) ^ @c ) || (((@g || @ag) && @l) ^ @c ^ @u)
      end

      def options_invalid?
        !options_valid?
      end

      def options_help
        puts "invalid option combination."
        help_msg
      end

      def help_msg
        puts ''
        GitmylabCli.task_help(shell, command)
        exit(0)
      end

      def command
        self.class.namespace.split(':').last.to_sym
      end

    end

  end
end
