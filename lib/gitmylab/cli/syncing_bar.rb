module Gitmylab
  module Cli

    class SyncingBar

      def initialize(options)
        @title                = options[:title] || ""
        @sub_title            = ''
        @total                = options[:total] || 0
        @sub_title_max_length = options[:sub_title_max_length] || 0
        @bar                  = nil
      end

      def title_full_length
        @title.length + @sub_title_max_length
      end

      def title_effective_length
        @title.length + @sub_title.length
      end

      def full_title
        @title + @sub_title + ' '*(title_full_length - title_effective_length)
      end

      def increment(sub_title='')
        @sub_title = sub_title
        bar.title = full_title
        bar.increment if Cli::Message.level > 0
      end

      def finish
        bar.finish if Cli::Message.level > 0
      end

      def progress
        bar.progress if Cli::Message.level > 0
      end

      def total
        bar.total if Cli::Message.level > 0
      end

      def pause
        bar.pause if Cli::Message.level > 0
      end

      def resume
        bar.resume if Cli::Message.level > 0
      end

      def log(msg)
        bar.log(msg) if Cli::Message.level > 0
      end

      private

      def bar
        @bar ||= ProgressBar.create(
          :title       => full_title,
          :starting_at => 0,
          :total       => @total,
          :format      => '%t %c/%C [%B]'
        )
      end

    end

  end
end
