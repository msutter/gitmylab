module Gitmylab
  module Access
    class Permission

      include Utils::Helpers

      def initialize(user, item, access_level=nil)
        @user              = user
        @item              = item
        @access_level      = access_level
        @item_access_class = "Gitmylab::Access::#{class_lastname(@item)}".constantize
      end

      def list
        p = @item_access_class.new(@user, @item)
        @access_level = p.get
        @access_level ? @access_level.to_s : nil
      end

      def create(options)
        p = @item_access_class.new(@user, @item)
        p.set(@access_level, options)
      end

      def remove
        p = @item_access_class.new(@user, @item)
        p.delete
      end

    end
  end
end
