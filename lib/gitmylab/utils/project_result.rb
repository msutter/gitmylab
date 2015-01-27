module Gitmylab
  module Utils

    class ProjectResult

      attr_accessor :command
      attr_accessor :action
      attr_accessor :status
      attr_accessor :message

      def initialize(project)
        @project = project
      end

      def render

        m                            = Cli::Message.new(@project.location)
        m.end_newline                = true
        m.indent                     = 0
        m.prepend                    = '==> '
        m.color                      = Cli::Color.status_color(@status)

        action_message               = Cli::Message.new(@message)
        action_message.indent        = 2
        action_message.prepend       = ''
        action_message.start_newline = true
        action_message.end_newline   = true
        action_message.color         = Cli::Color.status_color(@status)

        end_m                        = Cli::Message.new("#{@action.to_s} #{@status.to_s}")
        end_m.indent                 = 0
        end_m.prepend                = '==> '
        end_m.color                  = Cli::Color.status_color(@status)

        m.sub(action_message)
        m.sub(end_m)
        m.render

      end

    end

  end
end
