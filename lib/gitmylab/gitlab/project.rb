module Gitmylab
  module Gitlab

    class Project < Gitlab::Base

      def self.object_symbol
        :projects
      end

      def self.filter_by_projects_and_groups(selections)

        opi = selections[:projects_include]
        ope = selections[:projects_exclude]
        ogi = selections[:groups_include]
        oge = selections[:groups_exclude]

        self.all.select do |project|
          # projects include/exclude
          (opi == :all || opi.include?(project.path)) && !ope.include?(project.path) and
          # groups include/exclude
          (ogi == :all || ogi.include?(project.namespace.path)) && !oge.include?(project.namespace.path)
        end
      end

      attr_accessor

      def initialize(gitlab_object)
        @unracked = []
        super(gitlab_object)
      end

      def refresh
        @members_cache= nil
      end

      def group
        Gitlab::Group.new(namespace)
      end

      def location
        File.join(group.location, path)
      end

      def members
        attributes = [id]
        @members_cache ||= list(::Gitlab, :team_members, attributes)
      end

      def member?(user)
        members.detect{|m| m.id == user.id} ? true : nil
      end

      def member_access(user)
        members.detect{|m| m.id == user.id}.access_level
      end

      def git
        @git ||= Git.open(location) if File.directory?(location)
      end

      def create_group_dir
        group_dir = group.location
        FileUtils.mkdir group_dir unless File.directory?(group_dir)
        group_dir
      end

      def clone
        Git.clone(http_url_to_repo, path, :path => group.location)
        # FileUtils.mkdir location unless File.directory?(location)
        # sh "git clone #{http_url_to_repo} #{location}"
      end

      def pull
        chdir
        sh "git pull"
      end

      def added
        git.status.added.keys
      end

      def changed
        git.status.changed.keys
      end

      def deleted
        git.status.deleted.keys
      end

      def unknown?
        sh "git diff-index 'HEAD'"
      end

      def unclean?
        binding.pry if self.name == 'mssql_2012'
        untracked.any? || added.any? || changed.any? || deleted.any?
      end

      def untracked
        @untracked ||= git.status.untracked.keys & files
      end

      def files
        chdir
        cmd = "git ls-files -z -d -m -o"
        cmd << " -X .gitignore" if File.exist?('.gitignore')
        `#{cmd}`.split("\x0")
      end

      def status
        chdir
        sh "git status"
      end

      def chdir
        Dir.chdir location
      end

      def branches
        ::Gitlab.branches(id)
      end

    end
  end
end
