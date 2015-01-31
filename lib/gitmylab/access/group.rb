module Gitmylab
  module Access

    class Group < Base

      def initialize(user, group)
        super(user, group)
        @group = @item
      end

      private

      def create(access_id)
        r = ::Gitlab.add_group_member(@group.id, @user.id, access_id)
        @group.refresh
        r
      end

      def remove
        r = ::Gitlab.remove_group_member(@group.id, @user.id)
        @group.refresh
        r
      end

    end
  end
end
