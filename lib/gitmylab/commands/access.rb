module Gitmylab
  module Commands

    module Access

      LeftAdjust  = 50
      RightAdjust = 10
      Tab         = '.' + ' '*(LeftAdjust+RightAdjust+3)

      def access(cli_options)
        roles = []

        if cli_options['config_file']
          #roles = parsed_config
        else
          selected_items = select_items(cli_options)
          permissions = []
          selected_items.each do |item|
            if cli_options['users']
              cli_options['users'].each do |username|
                item.permissions << Gitmylab::Access::Permission.new(username, item, cli_options['level'], cli_options['regression'])
              end
            else
              item.permissions << Gitmylab::Access::Permission.new(nil, item, cli_options['level'], cli_options['regression'])
            end
          end
          access_role_iterator(selected_items)
        end
      end

      def access_role_iterator(items)

        cli_iterator items do |item|
          sr         = Cli::Result.new(item)
          sr.command = @command
          sr.action  = @action
          sr.message = ''

          if item.permissions.any?
            item.permissions.each do |permission|
              if permission.user
                case @action
                when :list
                  if permission.list
                    sr.message << "#{(permission.user.username + ' / ' + permission.user.name).ljust(LeftAdjust)} => #{' '*RightAdjust + permission.access_level.to_s}\n"
                    sr.status  = :success
                  else
                    sr.message << "#{(permission.user.username + '/' + permission.user.name).ljust(LeftAdjust)} => #{' '*RightAdjust}No direct access to #{item.path}\n"
                    sr.status  = :skip
                  end
                when :add
                when :remove
                end
              elsif permission.username.nil?
                item.members.each do |member|
                  user = Gitmylab::Gitlab::User.find_by_username(member.username).first
                  sr.message << "#{(member.username + ' / ' + user.name).ljust(LeftAdjust)} => #{' '*RightAdjust + member.access_level.to_s}\n"
                  sr.status  = :success
                end
              else
                sr.status  = :skip
                sr.message << "User #{permission.username} not found !\n"
              end
            end
          else
            sr.message << "No members found for #{item.path}\n"
            sr.status  = :empty
          end
          sr.render
        end
      end


      def access_iterator(cli_options, enumerable)
        cli_iterator enumerable do |item|
          sr         = Cli::Result.new(item)
          sr.command = @command
          sr.action  = @action
          sr.message = ''
          if cli_options['users']
            cli_options['users'].each do |username|
              user = Gitmylab::Gitlab::User.find_by_username(username).first
              if user
                permission = Gitmylab::Access::Permission.new(user, item, cli_options['level'])
                case @action
                when :list
                  if permission.list
                    sr.message << "#{(user.username + ' / ' + user.name).ljust(LeftAdjust)} => #{' '*RightAdjust + access_level}\n"
                    sr.status  = :success
                  else
                    sr.message << "#{(user.username + '/' + user.name).ljust(LeftAdjust)} => #{' '*RightAdjust}No direct access to #{item.path}\n"
                    sr.status  = :skip
                  end
                when :add
                  options = {:regression => cli_options['regression']}
                  r = permission.create(options)
                  sr.status = r.status
                  sr.message << case r.reason
                  when :exists then "#{user.username} already has #{r.access} access !\n"
                  when :regression then "#{user.username} already has #{r.access} access !, Use -R to force regression\n"
                  else "Access Level #{cli_options['level']} set for #{user.username}\n"
                  end
                when :remove
                  access_level = permission.list
                  if permission.list
                    r = permission.remove
                    sr.status = :success
                    sr.message << "Access #{access_level} removed for #{user.username}.\n"
                  else
                    sr.message << "User #{user.username} already has no access.\n"
                    sr.status = :skip
                  end
                end
              else
                sr.status  = :skip
                sr.message = "User #{username} not found !\n"
              end
            end
          else
            # only for action list without defined users
            users_selection = item.members
            sr.message << "No members found for #{item.path}\n" if users_selection.empty?
            sr.status  = :empty

            users_selection.sort_by{|member| member.access_level }.reverse.each do |member|
              access_name = Gitmylab::Access::Base.access_name(member.access_level)
              sr.message << "#{(member.username + ' / ' + member.name).ljust(LeftAdjust)} => #{' '*RightAdjust + access_name.to_s}\n"
              sr.status  = :success
            end
          end
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
