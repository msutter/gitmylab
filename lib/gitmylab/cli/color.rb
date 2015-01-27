module Gitmylab
  module Cli

    class Color

      @@map = {
        :success   => :green,
        :fail      => :red,
        :skip      => :magenta,
        :empty     => :blue,
        :original  => nil
      }

      def self.map
        @@map
      end

      def self.status_color(status)
        @@map[status]
      end

    end

  end
end