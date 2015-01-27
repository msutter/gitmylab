module Gitmylab
  module Cli

    module Helpers

      private

      def projects_and_groups_options_check(shell, command, options)
        c = options[:config_file]
        a = options[:all]
        p = options[:projects] ? options[:projects].any? : false
        g = options[:groups] ? options[:groups].any? : false

        # mutually exclusive project options
        unless (p ^ c ^ a) || (g ^ c ^ a)
          if p
            puts "Use only one of [--all(-a)], [--projects(-p)] or [--config_file(-c)],"
          elsif g
            puts "Use only one of [--all(-a)], [--groups(-g)] or [--config_file(-c)],"
          else
            puts "No option specified !"
          end
          puts ''
          GitmylabCli.task_help(shell, command)
          exit(0)
        end
      end

      def command
        self.class.namespace.split(':').last.to_sym
      end

    end

  end

end
