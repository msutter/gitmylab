module Gitmylab
  module Cli

    class FakeStdout

      attr_accessor :output

      def initialize
        @output = ""
      end

      def write(string)
        @output << string
      end

      def flush
      end

      def print(string)
        @output << string
      end

    end
  end
end
