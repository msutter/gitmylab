module Gitmylab
  module Commands

    module Branch

      def branch(cli_options)
        selected_projects = select_projects(cli_options)
        exit 1 if selected_projects.empty?
        cli_iterator selected_projects do |project|
          sr         = Cli::Result.new(project)
          sr.command = @command
          sr.action  = @action
          branches = project.branches

          case @action
          when :list
            sr.status  = :empty
            sr.message = branches.count < 1 ? 'No branches found !' : ''

            branches.each do |branch|
              sr.status  = :success
              sr.message << branch.name
              sr.message << " [ protected ]" if branch.protected
              sr.message << "\n"
            end

          when :add
            if branches.any? {|b| b.name == cli_options['branch_name']}
              sr.status  = :skip
              sr.message = "branch #{cli_options['branch_name']} already exists !"
            else
              if project.default_branch
                ::Gitlab.create_branch(project.id, cli_options['branch_name'], cli_options['ref'])
                ::Gitlab.protect_branch(project.id, cli_options['branch_name']) if cli_options['protected']
                sr.status  = :success
                sr.message = "branch #{cli_options['branch_name']} created"
                sr.message << " and protected" if cli_options['protected']
              else
                sr.status  = :skip
                sr.message = "No default branch found.\nThis often appends with empty gitlab repositories"
              end
            end

          when :protect
            if branch = branches.detect {|b| b.name == cli_options['branch_name']}
              if branch.protected
                sr.status  = :skip
                sr.message = "branch #{cli_options['branch_name']} already protected !"
              else
                ::Gitlab.protect_branch(project.id, cli_options['branch_name'])
                sr.status  = :success
                sr.message = "branch #{cli_options['branch_name']} is now protected"
              end
            else
              sr.status  = :skip
              sr.message = "branch #{cli_options['branch_name']} not found !"
            end

          when :unprotect
            if branch = branches.detect {|b| b.name == cli_options['branch_name']}
              unless branch.protected
                sr.status  = :skip
                sr.message = "branch #{cli_options['branch_name']} already unprotected !"
              else
                ::Gitlab.unprotect_branch(project.id, cli_options['branch_name'])
                sr.status  = :success
                sr.message = "branch #{cli_options['branch_name']} is now unprotected"
              end
            else
              sr.status  = :skip
              sr.message = "branch #{cli_options['branch_name']} not found !"
            end

          end
          sr.render
        end

      end

    end
  end
end
