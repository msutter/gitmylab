module Gitmylab
  module Access
    class Role

      @@config = nil

      def self.select_from_config(config)

      end

      def initialize(role, options={})
        @name                 = role
        @group_permissions    = options[:group_permissions]
        @project_permissions  = options[:project_permissions]
        @sub_role_permissions = options[:sub_role_permissions]
      end

    end
  end
end
