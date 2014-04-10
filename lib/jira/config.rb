class Jira::Config

  class << self
    def start; self.new end
  end

  attr_accessor :endpoint, :username, :password

  #
  # @raise
  #
  def initialize
    # if can't read from default configuration file location
    #   raise InstallationException
    # otherwise
    #   load all variables into memory
  end

end
