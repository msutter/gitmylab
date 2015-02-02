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

          items = access_iterator(selected_items)

          if cli_options['dump_config_file']
            write_config(items)
          end

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
        items
      end

      def write_config(items)
        roles = dump_roles(items)
        puts roles.to_yaml
      end

      def dump_roles(items)
        all_permissions = items.collect{|i| i.permissions.collect{|p| p}}.flatten

        # group permissions by projects/groups with same access_level
        permissions_groups_on_same_level_and_item = all_permissions.group_by do |p|
          p.type + '_' + p.item.path + '_' + p.access_level.to_s
        end

        item_groups = {}
        permissions_groups_on_same_level_and_item.each do |permissions_group, permissions|
          item_groups[permissions_group] = {} unless item_groups[permissions_group]
          permissions.each do |permission|
            a = permission.access_level.to_s
            path = permission.item.path
            type = permission.type.downcase.pluralize
            u = permission.username
            item_groups[permissions_group][type] = {} unless item_groups[permissions_group][type]
            item_groups[permissions_group][type][path] = a
            item_groups[permissions_group]['users'] = [] unless item_groups[permissions_group]['users']
            item_groups[permissions_group]['users'] << u unless item_groups[permissions_group]['users'].include?(u)
          end
        end

        # create a role for users with same permissions on projects and groups
        users_groups = item_groups.group_by do |item_name, item_group|
          item_group['users'].sort.join(';')
        end

        roles = []
        users_groups.each_with_index do |user_group, i|
          projects = {}
          groups   = {}
          user_group.last.each do |group_name, item|
            projects.merge!(item['projects']) if item['projects']
            groups.merge!(item['groups']) if item['groups']
          end
          k = 'role_' + "%03d" % (i + 1)
          role = {k => {}}
          users = user_group.first.split(';')

          role[k]['projects'] = projects if projects.any?
          role[k]['groups']   = groups if groups.any?
          role[k]['users']    = users
          roles << role
        end
        roles
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
