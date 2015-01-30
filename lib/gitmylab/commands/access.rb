module Gitmylab
  module Commands

    module Access

      LeftAdjust  = 50
      RightAdjust = 10
      Tab         = '.' + ' '*(LeftAdjust+RightAdjust+3)

      def access_list(cli_options)
        # Projects
        selected_projects = select_projects(cli_options)
        if selected_projects.any?
          access_list_user_iterator(cli_options, selected_projects)
        end

        # Groups
        selected_groups = select_groups(cli_options)
        if selected_groups.any?
          access_list_user_iterator(cli_options, selected_groups)
        end
      end

      def access_add(cli_options)

        if selected_projects = select_projects(cli_options).any?
          cli_iterator cli_options, selected_projects do |project|
            sr         = Cli::Result.new(project)
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

        if selected_groupss = select_groups(cli_options).any?
        end

      end

      def access_list_user_iterator(cli_options, enumerable)
        cli_iterator cli_options, enumerable do |item|
          item_name = item.class.name.split(':').last.downcase
          sr         = Cli::Result.new(item)
          sr.command = @command
          sr.action  = @action
          sr.message = ''

          users_selection = []

          if cli_options['users']

            cli_options['users'].each do |username|
              user = Gitmylab::Gitlab::User.find_by_username(username).first
              if user
                member = item.members.detect{|member| user.username == member.username }
                users_selection << member if member
                case item_name
                when 'project' then
                  sr.message << "#{(user.username + '/' + user.name).ljust(LeftAdjust)} => #{' '*RightAdjust}No direct access to #{item_name} #{item.path}\n" unless member
                when 'group' then
                  sr.message << "#{(user.username + '/' + user.name).ljust(LeftAdjust)} => #{' '*RightAdjust}No access to #{item_name} #{item.path}\n" unless member
                end
                sr.status  = :skip
              else
                sr.message << "#{username.ljust(LeftAdjust)} => #{' '*RightAdjust + 'Account not found !'}\n"
                sr.status  = :skip
              end

            end
          else
            users_selection = item.members
            case item_name
            when 'project' then
              sr.message << "No members found for #{item_name} #{item.path}\n" if users_selection.empty?
            when 'group' then
              sr.message << "No members found for #{item_name} #{item.path}\n" if users_selection.empty?
            end
            sr.status  = :empty
          end

          users_selection.sort_by{|member| member.access_level }.reverse.each do |member|
            access_name = Gitmylab::Access::Base.access_name(member.access_level)
            sr.message << "#{(member.username + ' / ' + member.name).ljust(LeftAdjust)} => #{' '*RightAdjust + access_name.to_s}\n"
            sr.status  = :success
          end

          sr.message << ""
          sr.render
        end

      end

      def get_items_count(sp, sg)
        ic = spc + sgc
        if ic == 0
          puts 'No Items found Exiting....'.red
          exit 1
        end
        ic
      end

    end

  end
end
