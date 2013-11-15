#
# Installation Script
#

module Jira
  class CLI < Thor

    desc "install", "Guides the user through JIRA installation"
    def install
      url = ""
      begin
        create_file Jira::Core.url_path, nil, verbose:false do
          url = self.cli.ask("Enter your JIRA URL: ").strip
          # ensure protocol is set
          url = "http://" + url if !url[/^http(s):\/\//]
          # ensure that there are no trailing slashes
          url.gsub!(/\/+$/,'')
        end
      end while validate_endpoint(url)

      create_file Jira::Core.auth_path, nil, verbose:false do
        username = self.cli.ask("Enter your JIRA username: ")
        password = self.cli.ask("Enter your JIRA password: ") do |q|
          q.echo = false
        end
        "#{username.strip}:#{password.strip}"
      end

      Jira::Core.send(:discard_memoized)
    end

    protected

      #
      # Validates the input JIRA endpoint
      #
      # @param endpoint [String] endpoint address to validate
      #
      # @return [Boolean] true if validation succeeds
      #
      def validate_endpoint(endpoint)


      end

  end
end
