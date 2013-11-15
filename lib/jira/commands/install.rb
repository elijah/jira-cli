#
# Installation Script
#

module Jira
  class CLI < Thor

    desc "install", "Guides the user through JIRA installation"
    def install
      if !Jira::Core.key_exists?
        create_file Jira::Core.key_path, nil, verbose:false do
          puts "Created an encryption key at ~/.jira-key."
          SecureRandom.uuid
        end
        Encryptor.default_options.merge!(key: Jira::Core.key)
      end

      create_file Jira::Core.url_path, nil, verbose:false do
        self.cli.ask("Enter your JIRA URL: ")
      end

      create_file Jira::Core.auth_path, nil, verbose:false do
        username = self.cli.ask("Enter your JIRA username: ")
        password = self.cli.ask("Enter your JIRA password: ") do |q|
          q.echo = false
        end
        "#{username}:#{Jira::Core.encode(password.encrypt(salt:username))}"
      end

      Jira::Core.send(:discard_memoized)
    end

  end
end
