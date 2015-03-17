module Gitmylab
  module Commands

    module Branch

      def branch
        selected_projects = select_items
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
            if branches.any? {|b| b.name == @options['branch_name']}
              sr.status  = :skip
              sr.message = "branch #{@options['branch_name']} already exists !"
            else
              if project.default_branch
                ::Gitlab.create_branch(project.id, @options['branch_name'], @options['ref'])
                ::Gitlab.protect_branch(project.id, @options['branch_name']) if @options['protected']
                sr.status  = :success
                sr.message = "branch #{@options['branch_name']} created"
                sr.message << " and protected" if @options['protected']
              else
                sr.status  = :skip
                sr.message = "No default branch found.\nThis often appends with empty gitlab repositories"
              end
            end

          when :protect
            if branch = branches.detect {|b| b.name == @options['branch_name']}
              if branch.protected
                sr.status  = :skip
                sr.message = "branch #{@options['branch_name']} already protected !"
              else
                ::Gitlab.protect_branch(project.id, @options['branch_name'])
                sr.status  = :success
                sr.message = "branch #{@options['branch_name']} is now protected"
              end
            else
              sr.status  = :skip
              sr.message = "branch #{@options['branch_name']} not found !"
            end

          when :unprotect
            if branch = branches.detect {|b| b.name == @options['branch_name']}
              unless branch.protected
                sr.status  = :skip
                sr.message = "branch #{@options['branch_name']} already unprotected !"
              else
                ::Gitlab.unprotect_branch(project.id, @options['branch_name'])
                sr.status  = :success
                sr.message = "branch #{@options['branch_name']} is now unprotected"
              end
            else
              sr.status  = :skip
              sr.message = "branch #{@options['branch_name']} not found !"
            end

          when :diff
            branch_from = branches.detect {|b| b.name == @options['branch_from']}
            branch_to = branches.detect {|b| b.name == @options['branch_to']}
            if (branch_from && branch_to)
              # As compare method is not working, here a workaraund working with commits
              #diffs = ::Gitlab.compare(project.id, branch_from.name, branch_to.name )
              commits_from = ::Gitlab.commits(project.id, :ref_name => branch_from.name)
              commits_to = ::Gitlab.commits(project.id, :ref_name => branch_to.name)
              commits_diff = commits_from.reject{|cf| commits_to.collect{|ct| ct.id}.include?(cf.id)}
              sr.status  = :success
              if commits_diff.any?
                sr.status  = :skip
                sr.message = "#{commits_diff.count} commits differs:"
                commits_diff.each do |cd|
                  sr.message << "\n"
                  sr.message << "\ncommit #{cd.id}"
                  sr.message << "\ntitle: #{cd.title}"
                  sr.message << "\nreated_at: #{cd.created_at}"
                end

                if @options['create_merge_request']
                  pending_merge_requests = ::Gitlab.merge_requests(project.id)
                  unless pending_merge_requests.any?
                    merge_options = {
                      :source_branch => branch_from.name,
                      :target_branch => branch_to.name
                    }
                    ::Gitlab.create_merge_request(project.id, @options['merge_request_message'], merge_options)
                    sr.status  = :success
                    sr.message << "\n"
                    sr.message << "\nMerge Request '#{@options['merge_request_message']}' Created"
                    sr.message << "\n#{branch_from.name} --> #{branch_to.name}"

                  else
                    sr.status  = :skip
                    sr.message << "\n"
                    sr.message << "\n !!! Skipping the merge request creation !!!"
                    sr.message << "\n There are pending merge requests:"
                    pending_merge_requests.each do |mr|
                      sr.message << "\n"
                      sr.message << "\ntitle: #{mr.title}"
                      sr.message << "\nsource: #{mr.source_branch}"
                      sr.message << "\ntarget: #{mr.target_branch}"
                      sr.message << "\ncreated_at: #{mr.created_at}"
                      sr.message << "\nauthor: #{mr.author.email}"
                      sr.message << "\nassignee: #{mr.assignee}" if mr.assignee
                      if @options['accept_pending_merge_requests']
                        # # ::Gitlab.accept_merge_request not yet working as a put on '/projects/:id/merge_request/:merge_request_id/merge' gives 404 not found
                        sr.message << "\n"
                        sr.message << "\nAccept merge request not yet implemented !"
                        #   sr.status  = :skip
                        #   ::Gitlab.accept_merge_request(project.id, mr.id, :merge_commit_message => @options['merge_commit_message'])
                        #   sr.message << "\n"
                        #   sr.message << "\nPending merge request accepted with comment '#{@options['merge_commit_message']}'"
                      end
                    end
                    sr.message << "\n"
                    sr.message << "\n Please first accept the pending merge requests." unless @options['accept_pending_merge_requests']
                  end

                end

              else
                sr.status  = :success
                sr.message = "Branches in sync"
              end

            else
              sr.status  = :error
              sr.message = "branch #{@options['branch_from']} not found !" unless branch_from
              sr.message = "branch #{@options['branch_to']} not found !" unless branch_to
            end

          end
          sr.render
        end

      end

    end
  end
end
