module Gitmylab
  module Access
    class Permission

      include Utils::Helpers

      attr_accessor :username, :access_level, :regression, :item

      def initialize(username, item, access_level=nil, regression=nil)
        @username          = username
        @item              = item
        @access_level      = access_level
        @regression        = regression
        @item_class_name   = class_lastname(@item)
        @item_access_class = "Gitmylab::Access::#{@item_class_name}".constantize
      end

      def list
        p = @item_access_class.new(user, @item)
        # Gitmylab::Manager.spinner "Loading #{@item_class_name} members..." do
          @access_level = p.get
        # end
        @access_level ? @access_level.to_s : nil
      end

      def create
        p = @item_access_class.new(user, @item)
        p.set(@access_level, @regression)
      end

      def remove
        p = @item_access_class.new(user, @item)
        p.delete
      end

      def user
        @user ||= Gitmylab::Gitlab::User.find_by_username(@username).first
      end

      def type
        @item_class_name
      end

      def to_s
        "#{@item.path}: #{@username} ==> #{@access_level}"
      end

    end
  end
end
