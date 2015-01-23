module Gitmylab
  module Gitlab
    class User < Gitlab::Base

      def self.object_symbol
        :users
      end

      def initialize(gitlab_object)
        @groups = []
        super(gitlab_object)
      end

      def corporate_id
        extern_uid ? extern_uid.match(/^CN=([^,]+),/)[1] : nil
      end

      def group_memberships
        group_memberships = {}
        Gitlab::Group.all.each do |g|
          g.members.each do |m|
            group_memberships[g.path] = m.access_level if m.id == id
          end
        end
        group_memberships
      end

      def ad_user?
        ad_user ? true : nil
      end

      def ad_user
        ActiveDirectory::User.find(:first, :cn => corporate_id)
      end

      def ad_groups
        ad_user.groups
      end

    end
  end
end
