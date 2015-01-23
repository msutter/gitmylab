module Gitmylab
  module Access
    class Project < Access::Base

      def initialize(user, project)
        super(user, project)
        @project = @target

      end

      private

      def create(access_id)
        r = ::Gitlab.add_team_member(@project.id, @user.id, access_id)
        @project.refresh
        r
      end

      def remove
        r = ::Gitlab.remove_team_member(@project.id, @user.id)
        @project.refresh
        r
      end

    end
  end
end
