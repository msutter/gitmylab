module Gitmylab
  module Cli

    class LoadingBar

      def initialize
        @stop_loop = false
        @bar = nil
      end

      def run
        if Message.level > 0
          progress = Thread.new {
            loop do
              Thread.stop if @stop_loop
              sleep(0.2)
              bar.increment
            end
          }
        end
      end

      def log(msg)
        bar.log(msg)
      end

      def finish
        if Message.level > 0
          @stop_loop = true
          sleep(0.3)
          bar.total = 10000
          bar.finish
        end
      end

      private

      def bar
        @bar ||= ProgressBar.create(
          :title    => "Loading projects:",
          :starting => 20,
          :total    => nil,
          :format   => '%t [%B]'
        )
      end

    end

  end
end
