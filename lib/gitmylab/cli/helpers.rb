module Gitmylab
  module Cli

    module Helpers

      private

      def options_check(shell, command, options)
        @c  = options[:config_file]
        @a  = options[:all]
        @p  = options[:projects] ? options[:projects].any? : false
        @g  = options[:groups] ? options[:groups].any? : false
        @n  = options[:namespaces] ? options[:namespaces].any? : false
        @u  = options[:users] ? options[:users].any? : false
        @l  = options[:level] ? true : false
        @an = options[:all_namespaces]

        options_help if options_invalid?

      end

      def options_valid?
        ((@p || @g) ^ @a ^ @c) || (((@n || @an) && @u && @l) ^ @c)
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
