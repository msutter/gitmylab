module Gitmylab
  module Commands

    module Access

      def access_add(cli_options)
        selected_projects = select_sync_projects(cli_options)

        project_iterator cli_options, selected_projects do |project|
          sr         = Utils::ProjectResult.new(project)
          sr.command = @command
          sr.action  = @action
          users = Gitmylab::Gitlab::User.find_by_username(cli_options['user'])

          if users.any?
            user = users.first
            project_access = Gitmylab::Access::Project.new(user, project)
            options = {:regression => cli_options['regression']}
            r = project_access.set(cli_options['level'].to_sym, options)
            sr.status = r.status

            sr.message = case r.reason
            when :exists then "Access already exists !"
            when :regression then "Access already exists with greater permissions!. Use -R to force regression."
            else "Access Level #{cli_options['level']} granted to #{user.username}."
            end

          else
            sr.status  = :skip
            sr.message = "User #{cli_options['level']} not found !"
          end
          sr.render
        end
      end


      # selected_projects = select_access_projects(cli_options)
      # selected_groups = select_access_groups(cli_options)


    end

  end
end
