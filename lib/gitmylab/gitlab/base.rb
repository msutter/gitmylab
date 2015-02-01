module Gitmylab
  module Gitlab
    class Base

      include Gitmylab::Utils::Helpers

      class << self
        attr_accessor :instances_cache
      end

      # dynamically create find_by_* methods
      def self.method_missing(method_sym, *arguments, &block)
        # the first argument is a Symbol, so you need to_s it if you want to pattern match
        if method_sym.to_s =~ /^find_by_(.*)$/
          obj_array = self.all.select do |o|
            o.send($1.to_sym) == arguments.first
          end
        else
          super
        end
      end

      # also implement a correct respond_to? for the dynamic methods
      def self.respond_to?(method_sym, include_private = false)
        if method_sym.to_s =~ /^find_by_(.*)$/
          true
        else
          super
        end
      end

      def self.cached?
        self.instances_cache != nil
      end

      def self.refresh
        self.instances_cache = nil
        true
      end

      def self.all
        self.instances_cache ||= list(::Gitlab, self.object_symbol).collect{|gitlab_object| self.new(gitlab_object)}
      end

      def self.list(reciever, what, attributes=[])
        l = []
        iterate_over_all_pages(reciever, what, attributes) {|w| l << w}
        l
      end

      def self.iterate_over_all_pages(reciever, what, attributes=[], &blk)
        options = {}
        options[:page] = 1
        options[:per_page] = 100
        attributes.push(options)
        items = reciever.send(what,*attributes)
        while !items.empty? do
            items.each{|item| yield item }
            options[:page] += 1
            items = reciever.send(what, *attributes)
          end
        end

        attr_accessor :permissions

        def initialize(gitlab_object)
          @gitlab_object = gitlab_object
          @permissions = nil

          # auto-generate instance methods based on the gitlab @data hash
          gitlab_object.instance_variable_get(:@data).each do |key, value|
            (class << self; self end).send(:define_method, key.to_sym) { gitlab_object.send(key.to_sym) }
          end
        end

        def get_permissions
          @permissions ||= members.collect{|m| Gitmylab::Access::Permission.new(m.username, self, m.access_level)}
        end

        def type
          class_lastname(self)
        end

        def list(*args)
          self.class.list(*args)
        end

      end
    end
  end
