module Gitmylab

  class Manager

    attr_accessor :sync_results

    include Gitmylab::Commands::Project
    include Gitmylab::Commands::Branch
    include Gitmylab::Commands::Access

    include CommandLineReporter
    include Gitmylab::Utils::Helpers


    def initialize(command, action, options, shell=nil)
      Utils::Config.setup(command, action, options)
      @command        = command
      @action         = action
      @options        = options
      @shell          = shell
      @access_project = nil
      @sync_results   = []
    end

    # def report
    #   r = Cli::Report.new(@sync_results)
    #   r.render
    # end

    private

    def select_items
      horizontal_rule :width => terminal_width if Gitmylab::Cli::Message.level > 0
      items = spinner('Loading selected gitlab objects...') do
        project_selection = get_project_selections
        projects = Gitmylab::Gitlab::Project.filter_by_selection(project_selection)
        group_selection = get_groups_selections
        groups = Gitmylab::Gitlab::Group.filter_by_selection(group_selection)
        projects + groups
      end
      count_message('item', items)
      items
    end

    def get_project_selections

      # set default to no project
      pi = []
      pe = []
      ni = []
      ne = []

      case
      when @options.projects_include || @options.namespaces_include then
        pi = @options.projects_include ? @options.projects_include : :all
        ni = @options.namespaces_include ? @options.namespaces_include : :all

      when @options.all_projects then
        pi = :all
        ni = :all

      when @options.config_file then
        config_options = configatron.projects.to_hash if configatron.has_key?(:projects)

        # set options defaults if nothing else defined (all projects in all namespaces)
        pi = config_options[:projects_include] ? config_options[:projects_include] : :all
        ni = config_options[:namespaces_include]   ? config_options[:namespaces_include]   : :all

        pe += config_options[:projects_exclude] if config_options[:projects_exclude]
        ne += config_options[:namespaces_exclude] if config_options[:namespaces_exclude]
      end

      # finally add the exluded projects and namespaces from cli
      pe += @options.projects_exclude if @options.projects_exclude
      ne += @options.namespaces_exclude if @options.namespaces_exclude
      {
        :projects_include   => pi,
        :projects_exclude   => pe,
        :namespaces_include => ni,
        :namespaces_exclude => ne,
      }
    end

    def get_groups_selections
      groups_include = []
      groups_exclude = []
      case
      when @options.has_key?('groups') then
        groups_include = @options.groups ? @options.groups : []
      when @options.has_key?('all_groups') && @options.all_groups then
        groups_include = :all
      end
      {
        :groups_include => groups_include,
        :groups_exclude => groups_exclude
      }
    end

    def count_message(item_name, enumerable)
      if enumerable.count > 0

        many = enumerable.count > 1 ? true : false
        m = Cli::Message.new("#{enumerable.count} #{item_name}#{'s' if many} found")
        m.indent        = 0
        m.prepend       = '==> '
        m.color         = status_color(:success)
        m.start_newline = false
        m.end_newline   = true
        m.render

      else
        m = Cli::Message.new("No #{item_name} found.")
        m.indent        = 0
        m.prepend       = '==> '
        m.color         = status_color(:fail)
        m.start_newline = false
        m.end_newline   = true
        m.render
      end

    end

    def cli_iterator(enumerable, hide=false, &block)

      unless hide
        item_name = class_lastname(enumerable.first).downcase

        title_array = enumerable.collect{|p| p.title }
        title_max_length = title_array.max_by{|a|a.length}.length

        syncing_bar = Cli::SyncingBar.new(
          :title                => "#{@command.to_s} #{@action.to_s} ",
          :total                => enumerable.count,
          :sub_title_max_length => title_max_length,
        )
      end

      enumerable.each do |item|
        unless hide
          horizontal_rule :width => terminal_width if Cli::Message.level > 0
          syncing_bar.resume
          syncing_bar.increment(item.title)
          syncing_bar.pause
          horizontal_rule :width => terminal_width if Cli::Message.level > 0
        end
        # begin
        yield item
        # rescue => e
        #   sr         = Cli::Result.new(item)
        #   sr.command = @command
        #   sr.action  = @action
        #   sr.status  = :fail
        #   sr.message = e.message
        #   sr.render
        # end
      end
      syncing_bar.finish unless hide

    end

    def status_color(status)
      Cli::Color.status_color(status)
    end
  end
end
