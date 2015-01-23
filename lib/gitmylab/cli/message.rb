module Gitmylab
  module Cli

    class Message

      @@level_map = {
        :silent    => 0,
        :info      => 1,
        :detailed  => 2,
        #default to info
        nil        => 1
      }

      @@level = 1

      def self.level
        @@level
      end

      def self.level_sym
        @@level_map.detect{|k,v| @@level == v}.first
      end

      def self.level=(level)
        @@level = @@level_map[level]
      end

      attr_accessor :message
      attr_accessor :start_newline
      attr_accessor :end_newline
      attr_accessor :color
      attr_accessor :indent
      attr_accessor :prepend

      def initialize(message, options={})
        @message       = message
        @start_newline = false
        @end_newline   = false
        @color         = options[color]    || nil
        @indent        = options[indent]   || 0
        @prepend       = options[prepend]  || ''
        @sub_messages  = []
      end

      def output(msg)
        @color ? puts(msg.send(@color)) : puts(msg)
      end

      def sub(message_instance)
        @sub_messages << message_instance
      end

      def newline
        puts ''
      end

      def render
        if @@level > 0
          newline if @start_newline

          message.each_line do |line|
            output (' '*@indent + @prepend + line.strip)
          end

          @sub_messages.each do |sub_message|
            sub_message.render
          end

          newline if @end_newline

        end
      end

    end

  end
end
