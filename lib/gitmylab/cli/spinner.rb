module Gitmylab
  module Cli

    class Spinner

      def initialize(msg, options={})
        @stop_loop = false
        @spinner   = nil
        @msg       = msg
        @stop_msg  = options[:stop_msg] || ''
        @format    = options[:format] || :spin_1
      end

      def run
        if Message.level > 0
          progress = Thread.new {
            loop do
              Thread.stop if @stop_loop
              sleep(0.2)
              spinner.spin
            end
          }
        end
      end

      def stop(stop_msg=@stop_msg)
        if Message.level > 0
          @stop_loop = true
          sleep(0.3)
          spinner.stop(stop_msg)
        end
      end

      private

      def spinner
        @spinner ||= TTY::Spinner.new(@msg, format: @format)
      end

    end

  end
end
