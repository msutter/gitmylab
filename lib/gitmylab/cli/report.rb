module Gitmylab
  module Cli

    class Report

      include CommandLineReporter

      def initialize(results)
        @results           = results
        @width             = current_width
        @color             = 'green'
        @status_max_lenght = 9
      end

      def render
        if Cli::Message.level > 0
          vertical_spacing
          horizontal_line
          vertical_spacing
          header(
            {
              :title     => 'Gitlab Sync Cli::Report',
              :width     => @width,
              :align     => 'center',
              :rule      => false,
              :color     => @color,
              :bold      => true,
              :timestamp => true
            }
          )
          project_location_tables
          summary_table

        end
      end

      def project_location_tables
        columns = 1
        table_width =  @width - 5

        horizontal_line
        table(:border => false, :width => @width ) do |mytable|
          row :header => true, :color => @color do
            column('Project locations grouped by status', :align => 'center' ,:width => table_width )
          end
        end
        horizontal_line

        statuses.each do |status|

          if @results.detect{|r| status == r.status}

            table(:border => true, :width => @width ) do |mytable|
              row :header => true, :color => color(status) do
                column("#{status}", :align => 'left' ,:width => table_width )
              end
              @results.select{|r| status == r.status }.each do |result|
                row :color => color(result.status) do
                  column("#{result.project.location}", :width => table_width )
                end
              end
            end

          end

        end
      end

      def summary_table
        columns = 2
        table_width =  @width - 5

        horizontal_line
        table(:border => false, :width => @width ) do |mytable|
          row :header => true, :color => @color do
            column('Summary', :align => 'center' ,:width => table_width )
          end
        end
        horizontal_line

        table(:border => true, :width => @width) do |mytable|
          row :header => true, :color => @color do
            column('Status', :width => @status_max_lenght )
            column('Count')
          end
          statuses.each do |status|
            row :color => color(status) do
              column(status)
              column(count(status))
            end
          end
        end

      end

      private

      def color(type)
        Cli::Color.type_color(type)
      end

      def statuses
        Cli::Color.map.keys
      end

      def horizontal_line
        horizontal_rule :width => @width, :color => @color, :bold => true
      end

      def columns_width
        ((current_width - 1 )/@columns).to_i
      end

      def current_width
        terminal_width
      end

      def max_lenght(string_array)
        string_array.reduce do |memo, string|
            memo.length > string.length ? memo : string
        end.length
      end

      def status_counts
        @results.collect{|r| count(r.status).to_s}
      end

      def project_pathes
        @results.collect{|r| r.project.path}
      end

      def group_pathes
        @results.collect{|r| r.project.group.path}
      end

      def project_locations
        @results.collect{|r| r.project.location}
      end

      def count(status)
        @results.count{|r| r.status == status}
      end

      def status_counts_max_lenght
        max_lenght(status_counts)
      end

      def project_pathes_max_lenght
        max_lenght(project_pathes)
      end

      def group_pathes_max_lenght
        max_lenght(group_pathes)
      end

      def project_locations_max_lenght
        max_lenght(project_locations)
      end


      # This code was copied and modified from Rake, available under MIT-LICENSE
      # Copyright (c) 2003, 2004 Jim Weirich
      def terminal_width
        return 80 unless unix?

        result = dynamic_width
        (result < 20) ? 80 : result
      rescue
        80
      end

      begin
        require 'io/console'

        def dynamic_width
          _rows, columns = IO.console.winsize
          columns
        end
      rescue LoadError
        def dynamic_width
          dynamic_width_stty.nonzero? || dynamic_width_tput
        end

        def dynamic_width_stty
          %x{stty size 2>/dev/null}.split[1].to_i
        end

        def dynamic_width_tput
          %x{tput cols 2>/dev/null}.to_i
        end
      end

      def unix?
        RUBY_PLATFORM =~ /(aix|darwin|linux|(net|free|open)bsd|cygwin|solaris|irix|hpux)/i
      end
    end

  end
end
