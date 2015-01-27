module Gitmylab
  module Commands

    module Project

      def project_sync(cli_options)
        # reset results
        @sync_results = []
        selected_projects = select_sync_projects(cli_options)
        project_iterator cli_options, selected_projects do |project|
          sr = Utils::ProjectResult.new(project)
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
          sr.render
          @sync_results << sr
        end
        @sync_results
      end

    end
  end
end
