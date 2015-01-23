module Gitmylab
  module Utils

    class SyncResult

      attr_accessor :action
      attr_accessor :status
      attr_accessor :message

      def initialize(project)
        @project = project
      end

      def render
        m                   = Cli::Message.new(@project.location)
        m.end_newline       = true
        m.indent            = 0
        m.prepend           = '==> '
        m.color             = Cli::Color.status_color(@status)

        git_m               = Cli::Message.new(@message)
        git_m.indent        = 2
        git_m.prepend       = ''
        git_m.start_newline = true
        git_m.end_newline   = true
        git_m.color         = Cli::Color.status_color(@status)

        end_m               = Cli::Message.new("#{@action.to_s} #{@status.to_s}")
        end_m.indent        = 0
        end_m.prepend       = '==> '
        end_m.color         = Cli::Color.status_color(@status)

        m.sub(git_m)
        m.sub(end_m)
        m.render
      end

    end

  end
end
