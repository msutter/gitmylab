require 'yaml'
require 'fileutils'
require 'open4'
require 'active_support/inflector'
require 'gitlab'
require 'git'
require 'active_directory'
require 'configatron'
require 'ruby-progressbar'
require 'command_line_reporter'
require 'tty-spinner'
require 'pry'

module Gitmylab

  LIB_PATH = File.dirname(__FILE__)

  require_relative "gitmylab/utils/helpers"
  require_relative "gitmylab/utils/config"

  require_relative "gitmylab/gitlab/base"
  require_relative "gitmylab/gitlab/user"
  require_relative "gitmylab/gitlab/group"
  require_relative "gitmylab/gitlab/project"

  require_relative "gitmylab/access/base"
  require_relative "gitmylab/access/group"
  require_relative "gitmylab/access/project"
  require_relative "gitmylab/access/permission"
  require_relative "gitmylab/access/role"

  require_relative 'gitmylab/cli/helpers'
  require_relative 'gitmylab/cli/project'
  require_relative 'gitmylab/cli/branch'
  require_relative 'gitmylab/cli/access'
  require_relative "gitmylab/cli/result"
  require_relative 'gitmylab/cli/color'
  require_relative 'gitmylab/cli/message'
  require_relative 'gitmylab/cli/spinner'
  require_relative 'gitmylab/cli/syncing_bar'
  require_relative 'gitmylab/cli/report'
  require_relative 'gitmylab/cli/fake_stdout'

  require_relative 'gitmylab/commands/project.rb'
  require_relative 'gitmylab/commands/branch.rb'
  require_relative 'gitmylab/commands/access.rb'

  require_relative "gitmylab/version"
  require_relative 'gitmylab/manager'


end