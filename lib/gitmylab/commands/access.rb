module Gitmylab
  module Commands

    module Access

      LeftAdjust  = 50
      RightAdjust = 10
      Tab         = '.' + ' '*(LeftAdjust+RightAdjust+3)

      def access

        roles = []

        if @action == :sync
          access_sync
        else
          selected_items = select_items

          selected_items.each do |item|
            if @options['users']
              permissions = []
              @options['users'].each do |username|
                permissions << Gitmylab::Access::Permission.new(username, item, @options['level'], @options['regression'])
              end
              item.permissions = permissions
            end
          end

          items = access_iterator(selected_items)

          if @options['dump_config_file']
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

        # creates a role for users with same permissions
        roles = {}
        users_groups.each_with_index do |user_group, i|
          projects = {}
          groups   = {}
          user_group.last.each do |group_name, item|
            projects.merge!(item['projects']) if item['projects']
            groups.merge!(item['groups']) if item['groups']
          end
          k = 'role_' + "%03d" % (i + 1)
          roles[k] = {}
          users = user_group.first.split(';')

          roles[k]['projects'] = projects if projects.any?
          roles[k]['groups']   = groups if groups.any?
          roles[k]['users']    = users
        end
        roles
      end

      def access_sync
        # # get all items
        # @options['all_groups']   = true
        # @options['all_projects'] = true

        items = select_items

        # get config file
        config_roles = configatron.has_key?(:roles) ? configatron.roles.to_hash : []

        items.each do |item|

          role_permissions = []
          item.permissions = nil
          spinner "Loading #{item.type.downcase} #{item.path} members..." do
            item.get_permissions
          end

          affected_roles = config_roles.select do |role_name, role_attributes|
            (
              item.type == 'Project' &&
              role_attributes.has_key?(:projects) &&
              role_attributes[:projects].keys.include?(item.path.downcase.to_sym)
            ) ||
            (
              item.type == 'Group' &&
              role_attributes.has_key?(:groups) &&
              role_attributes[:groups].keys.include?(item.path.downcase.to_sym)
            )
          end

          affected_roles.each do |role_name, role_attributes|
            config_permissions = []
            role_attributes[:users].each do |user|

              if role_attributes.has_key?(:projects) && role_attributes[:projects].keys.include?(item.path.to_sym)
                role_attributes[:projects].each do |project, level|
                  config_permissions << Gitmylab::Access::Permission.new(user, item, level, @options[:regression])
                end
              end

              if role_attributes.has_key?(:groups) && role_attributes[:groups].keys.include?(item.path.to_sym)
                role_attributes[:groups].each do |group, level|
                  config_permissions << Gitmylab::Access::Permission.new(user, item, level, @options[:regression])
                end
              end

            end
            role_permissions += config_permissions
          end

          # compare permissions
          permissions_to_delete = item.permissions.reject do |ap|
            role_permissions.detect{|rp| ap.user == rp.user }
          end

          # Add permissions
          item.permissions = role_permissions
          @action = :add
          access_iterator([item]) if item.permissions.any?

          if @options[:force_deletion]
          # Remove permissions not defined in Roles
            item.permissions = permissions_to_delete
            @action = :remove
            access_iterator([item]) if item.permissions.any?
          end

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
