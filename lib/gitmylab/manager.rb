module Gitmylab

  class Manager

    attr_accessor :sync_results

    include CommandLineReporter
    include Gitmylab::Utils::Helpers

    def initialize(command, action)
      @command = command
      @action = action
      @access_project = nil
      @sync_results = []
      Utils::Config.setup(command)
    end

    # def report
    #   r = Cli::Report.new(@sync_results)
    #   r.render
    # end

    def branch_list(cli_options)
      selected_projects = select_sync_projects(cli_options)

      project_iterator cli_options, selected_projects do |project|
        branches   = project.branches

        sr         = Utils::ProjectResult.new(project)
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

        binding.pry
        sr.render
      end
    end

    def branch_add(cli_options)
      selected_projects = select_sync_projects(cli_options)

      project_iterator cli_options, selected_projects do |project|
        sr         = Utils::ProjectResult.new(project)
        sr.command = @command
        sr.action  = @action

        if project.branches.any? {|b| b.name == cli_options['name']}
          sr.status  = :skip
          sr.message = "branch #{cli_options['name']} already exists !"
        else
          ::Gitlab.create_branch(project.id, cli_options['name'], cli_options['ref'])
          sr.status  = :success
          sr.message = "branch #{cli_options['name']} created"
        end
        sr.render
      end

    end

    def branch_protect(cli_options)
      selected_projects = select_sync_projects(cli_options)

      project_iterator cli_options, selected_projects do |project|
        sr         = Utils::ProjectResult.new(project)
        sr.command = @command
        sr.action  = @action

        if project.branches.any? {|b| b.name == cli_options['name']}
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

    def access_add(cli_options)
      selected_projects = select_access_projects(cli_options)
      selected_groups = select_access_groups(cli_options)
      binding.pry
    end

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

    def project_iterator(options, enumerable, &block)

      syncing_bar = Cli::SyncingBar.new(
        :title                => "#{@command.to_s} #{@action.to_s} ",
        :total                => enumerable.count,
        :sub_title_max_length => @path_max_length,
      )

      iterations = enumerable.size
      counter = 0
      enumerable.each do |item|
        horizontal_rule :width => terminal_width
        syncing_bar.resume
        syncing_bar.increment(item.path)
        syncing_bar.pause
        horizontal_rule :width => terminal_width
        yield item
      end
      syncing_bar.finish

    end

    def status_color(status)
      Cli::Color.status_color(status)
    end
  end
end
