module Gitmylab
  module Utils

    module Helpers

      module ClassMethods
      end

      module InstanceMethods
        # This code was copied and modified from Rake, available under MIT-LICENSE
        # Copyright (c) 2003, 2004 Jim Weirich
        def terminal_width
          return 80 unless unix?

          result = dynamic_width
          (result < 20) ? 80 : result
        rescue
          80
        end

        begin
          require 'io/console'

          def dynamic_width
            _rows, columns = IO.console.winsize
            columns
          end
        rescue LoadError
          def dynamic_width
            dynamic_width_stty.nonzero? || dynamic_width_tput
          end

          def dynamic_width_stty
            %x{stty size 2>/dev/null}.split[1].to_i
          end

          def dynamic_width_tput
            %x{tput cols 2>/dev/null}.to_i
          end
        end

        def unix?
          RUBY_PLATFORM =~ /(aix|darwin|linux|(net|free|open)bsd|cygwin|solaris|irix|hpux)/i
        end

        def sh(*args)
          command = args.join(' ')
          exe = Open4::popen4(command) do |pid, stdin, stdout, stderr|
            @pid=pid
            @stdin=command
            @stdout=""
            @stderr=""

            while(line=stdout.gets)
              @stdout+=line
            end

            while(line=stderr.gets)
              @stderr+=line
            end

            unless @stdout.nil?
              @stdout=@stdout.strip
            end

            unless @stderr.nil?
              @stderr=@stderr.strip
            end

          end

          message = String.new
          message << @stderr unless @stderr.empty?
          message << "\n" unless (@stderr.empty? || @stdout.empty?)
          message << @stdout unless @stdout.empty?

          rc = exe.to_i
          status = rc == 0 ? :success : :fail
          r = Struct.new(:message, :status)
          r.new(message, status)
        end

      end

      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
      end

    end

  end
end
