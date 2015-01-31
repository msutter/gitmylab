module Gitmylab
  module Commands

    module Project

      def project(cli_options)
        # reset results
        @sync_results = []
        selected_projects = select_projects(cli_options)
        exit 1 if selected_projects.empty?
        cli_iterator selected_projects do |project|
          sr         = Cli::Result.new(project)
          sr.command = @command
          sr.action  = @action
          case @action
          when :sync
            group_dir = project.create_group_dir
            # check if project directory exists to update/clone
            if File.directory?(project.location)
              sr.action = :pull
              if project.default_branch
                r = project.pull
                sr.status  = r.status
                sr.message = r.message
              else
                sr.status  = :skip
                sr.message = "No default branch found.\nThis often appends with empty gitlab repositories"
              end
            else
              r = project.clone
              sr.action  = :clone

              sr.status  = :success
              sr.message = "Cloning into '#{project.location}'"
            end

          end
          sr.render
          @sync_results << sr
        end
        @sync_results
      end

    end
  end
end
