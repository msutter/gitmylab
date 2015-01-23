module Gitmylab

  class Manager

    attr_accessor :sync_results

    include CommandLineReporter
    include Gitmylab::Utils::Helpers

    def initialize(command)
      @access_project = nil
      @sync_results = []
      Utils::Config.setup(command)
    end

    # def report
    #   r = Cli::Report.new(@sync_results)
    #   r.render
    # end

    def branch_add(cli_options)
      selected_projects = select_sync_projects(cli_options)
      selected_projects.each do |project|
        project.branches
      end
    end

    def access_add(cli_options)
      selected_projects = select_access_projects(cli_options)
      selected_groups = select_access_groups(cli_options)
      binding.pry
    end

    def project_sync(cli_options)
      # reset results
      @sync_results = []

      selected_projects = select_sync_projects(cli_options)

      # add syncing progress bars
      syncing_bar = Cli::SyncingBar.new(
        :title                => 'Syncing project ',
        :total                => selected_projects.count,
        :sub_title_max_length => @path_max_length,
      )

      selected_projects.each_with_index do |project, i|
        horizontal_rule :width => terminal_width
        syncing_bar.resume
        syncing_bar.increment(project.path)
        sr = Utils::SyncResult.new(project)
        group_dir = project.create_group_dir

        # check if project directory exists to update/clone
        if File.directory?(project.location)
          sr.action = :pull

          if project.default_branch
            r = project.pull
            sr.status  = r.status
            sr.message = r.message

            ## skipping the unclean files part for now
            # if project.unclean?
            #   r = project.status

            #   status_msg         = Cli::Message.new("Warning: not in sync with remote branch")
            #   status_msg.indent  = 0
            #   status_msg.prepend = '==> '
            #   status_msg.color   = :yellow

            #   git_status_msg               = Cli::Message.new(r.message)
            #   git_status_msg.indent        = 2
            #   git_status_msg.color         = :yellow
            #   git_status_msg.start_newline = true
            #   git_status_msg.end_newline   = true

            #   status_msg.sub(git_status_msg)
            # end

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

        syncing_bar.pause
        horizontal_rule :width => terminal_width
        sr.render
        @sync_results << sr
      end

      syncing_bar.finish
      @sync_results
    end

    private

    def select_groups(cli_options)
      selections = get_selections(cli_options)
      Gitmylab::Gitlab::Groups.filter_by_projects_and_groups(selections)
    end

    def select_sync_projects(cli_options)
      # add loading spinner
      spinner = Cli::Spinner.new('Loading selected gitlab projects...')
      spinner.run

      selections = get_selections(cli_options)
      projects = Gitmylab::Gitlab::Project.filter_by_projects_and_groups(selections)
      if projects.count > 0
        path_array = projects.collect{|p| p.path }
        @path_max_length = path_array.max_by{|a|a.length}.length
        many = projects.count > 1 ? true : false
        spinner.stop(" Done")
        m = Cli::Message.new("#{projects.count} project#{'s' if many} found")
        m.indent        = 0
        m.prepend       = '==> '
        m.color         = status_color(:success)
        m.start_newline = true
        m.end_newline   = true
        m.render
        projects
      else
        spinner.stop(" Done")
        m = Cli::Message.new('No projects found. Exiting...')
        m.indent        = 0
        m.prepend       = '==> '
        m.color         = status_color(:fail)
        m.start_newline = true
        m.end_newline   = true
        m.render
        exit 1
      end

    end

    def get_selections(cli_options)

      # set default to no project
      opi = []
      ope = []
      ogi = []
      oge = []

      case
      when cli_options.all then
        opi = :all
        ogi = :all

      when cli_options.config_file then
        config_options = {}
        config_options.merge!(configatron.include.to_hash) if configatron.has_key?(:include)
        config_options.merge!(configatron.exclude.to_hash) if configatron.has_key?(:exclude)

        # set options defaults if nothing else defined (all projects in all groups)
        opi = config_options[:projects_include] ? config_options[:projects_include] : :all
        ogi = config_options[:groups_include]   ? config_options[:groups_include]   : :all

        ope += config_options[:projects_exclude] if config_options[:projects_exclude]
        oge += config_options[:groups_exclude] if config_options[:groups_exclude]

      when cli_options.projects || cli_options.groups then
        opi = cli_options.projects ? cli_options.projects : :all
        ogi = cli_options.groups ? cli_options.groups : :all
      end

      # finally add the exluded projects and groups from cli
      ope += cli_options.projects_exclude if cli_options.projects_exclude
      oge += cli_options.groups_exclude if cli_options.groups_exclude

      {
        :projects_include => opi,
        :projects_exclude => ope,
        :groups_include   => ogi,
        :groups_exclude   => oge,
      }
    end



    def status_color(status)
      Cli::Color.status_color(status)
    end
  end
end
