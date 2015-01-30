module Gitmylab
  module Commands

    module Branch

      def branch_list(cli_options)
        selected_projects = select_projects(cli_options)
        exit 1 if selected_projects.empty?
        cli_iterator cli_options, selected_projects do |project|
          branches   = project.branches
          sr         = Cli::Result.new(project)
          sr.command = @command
          sr.action  = @action
          sr.status  = :empty
          sr.message = branches.count < 1 ? 'No branches found !' : ''

          branches.each do |branch|
            sr.status  = :success
            sr.message << branch.name
            sr.message << " [ protected ]" if branch.protected
            sr.message << "\n"
          end
          sr.render
        end
      end

      def branch_add(cli_options)
        selected_projects = select_projects(cli_options)
        exit 1 if selected_projects.empty?
        cli_iterator cli_options, selected_projects do |project|
          sr         = Cli::Result.new(project)
          sr.command = @command
          sr.action  = @action
          if project.branches.any? {|b| b.name == cli_options['name']}
            sr.status  = :skip
            sr.message = "branch #{cli_options['name']} already exists !"
          else
            if project.default_branch
              ::Gitlab.create_branch(project.id, cli_options['name'], cli_options['ref'])
              ::Gitlab.protect_branch(project.id, cli_options['name']) if cli_options['protected']
              sr.status  = :success
              sr.message = "branch #{cli_options['name']} created"
              sr.message << " and protected" if cli_options['protected']
            else
              sr.status  = :skip
              sr.message = "No default branch found.\nThis often appends with empty gitlab repositories"
            end
          end
          sr.render
        end

      end

      def branch_protect(cli_options)
        selected_projects = select_projects(cli_options)
        exit 1 if selected_projects.empty?
        cli_iterator cli_options, selected_projects do |project|
          sr         = Cli::Result.new(project)
          sr.command = @command
          sr.action  = @action

          if branch = project.branches.detect {|b| b.name == cli_options['name']}
            if branch.protected
              sr.status  = :skip
              sr.message = "branch #{cli_options['name']} already protected !"
            else
              ::Gitlab.protect_branch(project.id, cli_options['name'])
              sr.status  = :success
              sr.message = "branch #{cli_options['name']} is now protected"
            end
          else
            sr.status  = :skip
            sr.message = "branch #{cli_options['name']} not found !"
          end
          sr.render
        end
      end

      def branch_unprotect(cli_options)
        selected_projects = select_projects(cli_options)
        exit 1 if selected_projects.empty?
        cli_iterator cli_options, selected_projects do |project|
          sr         = Cli::Result.new(project)
          sr.command = @command
          sr.action  = @action

          if branch = project.branches.detect {|b| b.name == cli_options['name']}
            unless branch.protected
              sr.status  = :skip
              sr.message = "branch #{cli_options['name']} already unprotected !"
            else
              ::Gitlab.unprotect_branch(project.id, cli_options['name'])
              sr.status  = :success
              sr.message = "branch #{cli_options['name']} is now unprotected"
            end
          else
            sr.status  = :skip
            sr.message = "branch #{cli_options['name']} not found !"
          end
          sr.render
        end
      end

    end
  end
end
