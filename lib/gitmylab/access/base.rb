module Gitmylab
  module Access

    class Base

      @@access_map = {
        :guest     => 10,
        :reporter  => 20,
        :developer => 30,
        :master    => 40,
        :owner     => 50
      }

      def self.access_id(access_name)
        access_id = @@access_map[access_name]
        raise "Unknown access level name #{access_name}" if access_id.nil?
        access_id
      end

      def self.access_name(access_id)
        access_name = @@access_map.detect{|k,v| v == access_id}
        raise "Unknown access level id '#{access_id}'" if access_name.nil?
        access_name.first
      end

      def initialize(user, item)
        @user  = user
        @item  = item
      end

      def get
        member = @item.members.detect{|m| m.id == @user.id}
        if member
          current_access_id = member.access_level
          self.class.access_name(current_access_id)
        else
          nil
        end
      end

      # update access_level. User access level regression are disabled by default (:regression => false)
      def set(access_name, regression)
        access_id           = self.class.access_id(access_name.to_sym)
        current_access_name = get
        current_access_id   = current_access_name ? self.class.access_id(current_access_name) : nil

        # only do if wanted access not already set.
        unless current_access_id == access_id
          # only do if wanted access does not exists or is higher than current access.
          # note: you can force regression
          if current_access_id.nil? || regression || current_access_id < access_id
            remove if current_access_id
            create(access_id)
            OpenStruct.new(
              :status => :success,
              :access => access_name,
            )
          else
            OpenStruct.new(
              :status => :skip,
              :reason => :regression,
              :access => current_access_name,
            )
          end

        else
          # wanted access already set
          OpenStruct.new(
            :status => :skip,
            :reason => :exists,
            :access => current_access_name,
          )
        end
      end

      def delete
        remove
        OpenStruct.new(
          :status => :success,
          :access => nil,
        )
      end

    end
  end
end
