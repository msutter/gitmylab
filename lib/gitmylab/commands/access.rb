module Gitmylab
  module Commands

    module Access

      LeftAdjust  = 50
      RightAdjust = 10
      Tab         = '.' + ' '*(LeftAdjust+RightAdjust+3)

      def access

        roles = []

        case @action
        when :sync
          access_sync
        when :clean
          access_clean
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

          items = access_item_iterator(selected_items) if selected_items.any?

          if @options['dump_config_file']
            write_config(items)
          end

        end
      end

      def access_item_iterator(items)

        hide_item = true unless @action == :list
        cli_iterator items, hide_item  do |item|

          ir         = Cli::Result.new(item)
          ir.command = @command
          ir.action  = @action
          ir.message = ''

          if item.permissions.nil?
            spinner "Loading #{item.type.downcase} members..." do
              item.get_permissions
            end
          end

          if item.permissions.any?
            if hide_item
              access_permission_iterator(item.permissions)
            else
              access_permission_iterator(item.permissions, ir)
            end
          else
            ir.message << "no members found for #{item.path}\n"
            ir.status  = :empty
          end
          ir.render unless hide_item
        end
        items
      end

      def access_permission_iterator(permissions, result = nil)
        hide = result ? true : nil
        cli_iterator permissions, hide do |permission|
          if result
            pr = result
          else
            pr         = Cli::Result.new(permission.item)
            pr.command = @command
            pr.action  = @action
            pr.message = ''
          end

          if permission.user
            case @action
            when :list
              if permission.list
                pr.message << "#{(permission.user.username + ' / ' + permission.user.name).ljust(LeftAdjust)} => #{' '*RightAdjust + permission.access_level.to_s}\n"
              else
                pr.message << "#{(permission.user.username + '/' + permission.user.name).ljust(LeftAdjust)} => #{' '*RightAdjust}no direct access\n"
              end
            when :add
              r = permission.create
              pr.status = r.status
              pr.message << case r.reason
              when :exists then "user '#{permission.user.username}' already has access level '#{permission.access_level}'\n"
              when :regression then "user '#{permission.user.username}' already has access level '#{r.access}', Use -R to force regression to '#{permission.access_level}'\n"
              else "access level '#{permission.access_level}' set for user '#{permission.user.username}'\n"
              end
            when :remove
              access_level = permission.list
              if permission.list
                r = permission.remove
                pr.status = :success
                pr.message << "access level '#{permission.access_level}' removed for user '#{permission.user.username}'\n"
              else
                pr.message << "user '#{permission.user.username}' already has no access\n"
                pr.status = :skip
              end
            end
          else
            pr.status  = :skip
            pr.message << "user #{permission.username} not found !\n"
          end
          pr.render unless result
        end
      end

      def access_clean
        all_dups = []
        items = select_items
        projects = items.select{|i| i.type == 'Project'}

        group_projects = projects.group_by{|p| p.group.id}
        group_projects.each do |group_id, projects|
          group = Gitmylab::Gitlab::Group.find_by_id(group_id).first
          unless group.nil?
            spinner "Loading #{group.type.downcase} #{group.path} member permissions..." do
              group.get_permissions
            end unless group.permissions

            projects.each do |project|

              spinner "Loading #{project.type.downcase} #{project.path} member permissions..." do
                project.get_permissions
              end unless project.permissions

              duplicated_permissions = project.permissions.select do |pp|

                group.permissions.detect do |gp|
                  gp.username == pp.username &&
                    gp.access_level >= pp.access_level
                end
              end
              all_dups += duplicated_permissions
            end
          end
        end
        puts "\nFound #{all_dups.count.to_s} duplicated permissions\n"
        if all_dups.any?
          all_dups.each do |p|
            puts "#{p.item.path}: #{p.username}"
          end
          puts "\n"
          confirm = @shell.ask(
            'Delete these duplicated permissions ?',
            :limited_to => ['YES', 'NO']
          )
          exit 1 if (confirm != 'YES')
          @action = :remove
          access_permission_iterator(all_dups) if all_dups.any?
        end

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

        items = select_items
        all_role_permissions = []
        all_permissions_to_delete = []

        # get config file
        config_roles = configatron.has_key?(:roles) ? configatron.roles.to_hash : []

        items.each do |item|
          role_permissions = []

          item.permissions = nil

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
          all_role_permissions += role_permissions

          # compare with existing permissions
          if @options[:deletion]
            spinner "Comparing #{item.type.downcase} #{item.path} members access with defined roles..." do
              item.get_permissions
              permissions_to_delete = item.permissions.reject do |ap|
                role_permissions.detect{|rp| ap.user == rp.user }
              end
              all_permissions_to_delete += permissions_to_delete
            end
          end

        end
        @action = :add
        access_permission_iterator(all_role_permissions) if all_role_permissions.any?

        # Remove permissions not defined in Roles
        if @options[:deletion]
          @action = :remove
          access_permission_iterator(all_permissions_to_delete) if all_permissions_to_delete.any?
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
