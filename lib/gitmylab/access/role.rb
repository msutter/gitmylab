module Gitmylab
  module Access
    class Role

      attr_reader :permissions

      def initialize(name, permissions=[])
        @name            = name
        @permissions     = permissions
      end

    end
  end
end
