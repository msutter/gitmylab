module Gitmylab

  class Manager

    attr_accessor :sync_results

    include Gitmylab::Commands::Project
    include Gitmylab::Commands::Branch
    include Gitmylab::Commands::Access

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

    private

    def select_projects(cli_options)
      projects = spinner('Loading selected gitlab projects...') do
        project_selection = get_project_selections(cli_options)
        Gitmylab::Gitlab::Project.filter_by_selection(project_selection)
      end

      count_message('project', projects)
      projects
    end

    def select_groups(cli_options)
      group_selection = get_groups_selections(cli_options)
      groups = spinner('Loading selected gitlab groups...') do
        Gitmylab::Gitlab::Group.filter_by_selection(group_selection)
      end
      count_message('group', groups)
      groups
    end

    def get_groups_selections(cli_options)
      groups_include = []
      groups_exclude = []
      case
      when cli_options.has_key?('namespaces') then
        groups_include = cli_options.namespaces ? cli_options.namespaces : []
      when cli_options.has_key?('all_namespaces') && cli_options.all_namespaces then
        groups_include = :all
      end
      {
        :groups_include => groups_include
        :groups_exclude => groups_include
      }
    end

    def count_message(item_name, enumerable)
      if enumerable.count > 0
        path_array = enumerable.collect{|p| p.path }
        @path_max_length = path_array.max_by{|a|a.length}.length
        many = enumerable.count > 1 ? true : false
        m = Cli::Message.new("#{enumerable.count} #{item_name}#{'s' if many} found")
        m.indent        = 0
        m.prepend       = '==> '
        m.color         = status_color(:success)
        m.start_newline = true
        m.end_newline   = true
        m.render

      else
        m = Cli::Message.new("No #{item_name} found.")
        m.indent        = 0
        m.prepend       = '==> '
        m.color         = status_color(:fail)
        m.start_newline = true
        m.end_newline   = true
        m.render
      end

    end

    def get_project_selections(cli_options)

      # set default to no project
      opi = []
      ope = []
      ogi = []
      oge = []

      case
      when cli_options.projects || cli_options.groups then
        opi = cli_options.projects ? cli_options.projects : :all
        ogi = cli_options.groups ? cli_options.groups : :all

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


    def spinner(msg, &block)
      s = Cli::Spinner.new(msg)
      s.run
      enumerable = yield
      s.stop(" Done")
      enumerable
    end

    def project_iterator(options, enumerable, &block)

      syncing_bar = Cli::SyncingBar.new(
        :title                => "#{@command.to_s} #{@action.to_s} ",
        :total                => enumerable.count,
        :sub_title_max_length => @path_max_length,
      )

      enumerable.each do |item|
        horizontal_rule :width => terminal_width
        syncing_bar.resume
        syncing_bar.increment(item.path)
        syncing_bar.pause
        horizontal_rule :width => terminal_width
        begin
          yield item
        rescue => e
          sr         = Utils::ProjectResult.new(item)
          sr.command = @command
          sr.action  = @action
          sr.status  = :fail
          sr.message = e.message
          sr.render
        end
      end
      syncing_bar.finish

    end

    def status_color(status)
      Cli::Color.status_color(status)
    end
  end
end
