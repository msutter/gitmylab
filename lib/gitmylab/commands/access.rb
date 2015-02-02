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

          selected_items.each do |item|
            if cli_options['users']
              permissions = []
              cli_options['users'].each do |username|
                permissions << Gitmylab::Access::Permission.new(username, item, cli_options['level'], cli_options['regression'])
              end
              item.permissions = permissions
            end
          end

          access_iterator(selected_items)
        end
      end

      def access_iterator(items)

        cli_iterator items do |item|
          sr         = Cli::Result.new(item)
          sr.command = @command
          sr.action  = @action
          sr.message = ''

          if item.permissions.nil?
            spinner "Loading #{item.type.downcase} members..." do
              item.get_permissions
            end
          end

          if item.permissions.any?
            item.permissions.each do |permission|
              if permission.user
                case @action
                when :list
                  if permission.list
                    sr.message << "#{(permission.user.username + ' / ' + permission.user.name).ljust(LeftAdjust)} => #{' '*RightAdjust + permission.access_level.to_s}\n"
                    sr.status  = :success
                  else
                    sr.message << "#{(permission.user.username + '/' + permission.user.name).ljust(LeftAdjust)} => #{' '*RightAdjust}no direct access\n"
                    sr.status  = :skip
                  end
                when :add
                  r = permission.create
                  sr.status = r.status
                  sr.message << case r.reason
                  when :exists then "user '#{permission.user.username}' already has access level '#{permission.access_level}'\n"
                  when :regression then "user '#{permission.user.username}' already has access level '#{permission.access_level}', Use -R to force regression\n"
                  else "access level '#{permission.access_level}' set for user '#{permission.user.username}'\n"
                  end
                when :remove
                  access_level = permission.list
                  if permission.list
                    r = permission.remove
                    sr.status = :success
                    sr.message << "access level '#{permission.access_level}' removed for user '#{permission.user.username}'\n"
                  else
                    sr.message << "user '#{permission.user.username}' already has no access\n"
                    sr.status = :skip
                  end
                end
              else
                sr.status  = :skip
                sr.message << "user #{permission.username} not found !\n"
              end
            end
          else
            sr.message << "no members found for #{item.path}\n"
            sr.status  = :empty
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
