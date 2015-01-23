module Gitmylab
  module Gitlab

    class Group < Gitlab::Base

      def self.object_symbol
        :groups
      end

      def refresh
        @members_cache= nil
      end

      def members
        attributes = [id]
        @members_cache ||= list(Gitlab, :group_members, attributes)
      end

      def member?(user)
        members.detect{|m| m.id == user.id} ? true : nil
      end

      def location
        File.join(configatron.sync.gitlab_root_path, path)
      end

      def sync(root_path=configatron.sync.gitlab_root_path)
        group_dir = File.join(root_path, path)
        unless File.directory?(group_dir)
          FileUtils.mkdir group_dir
          OpenStruct.new(
            :status    => :success,
            :directory => group_dir,
          )
        else
          OpenStruct.new(
            :status    => :skipped,
            :reason    => :exists,
            :directory => group_dir,
          )
        end
      end

      def chdir
        Dir.chdir location
      end

    end
  end
end
