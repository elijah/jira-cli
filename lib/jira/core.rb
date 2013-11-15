module Jira
  class Core
    class << self

      #
      # Memoizes url, username, and password
      #
      def setup
        self.url
        self.auth
        Encryptor.default_options.merge!(key: self.key) if self.key_exists?
      end

      ### Virtual Attributes

      #
      # @return [String] JIRA project endpoint
      #
      def url
        @url ||= self.read(self.url_path)
      end

      #
      # @return [String] JIRA username
      #
      def username
        @username ||= self.auth.first
      end

      #
      # @return [String] JIRA password
      #
      def password
        @password ||= self.decode(self.auth.last).decrypt(salt:self.username)
      end

      #
      # @return [String] JIRA encryption key
      #
      def key
        @key ||= self.read(self.key_path)
      end

      #
      # @return [String] default ticket is the current branch
      #
      def ticket
        `git rev-parse --abbrev-ref HEAD`.strip
      end

      ### Helpers

      #
      # Determines whether or not the input ticket matches the expected JIRA
      # ticketing syntax. Outputs a warning that the input ticket isn't a valid
      # ticket.
      #
      # @param ticket [String] input ticket name
      # @param verbose [Boolean] verbose output of the ticket warning
      #
      # @return [Boolean] whether input string matches JIRA ticket syntax
      #
      def ticket?(ticket, verbose=true)
        !!ticket.to_s[/^[a-zA-Z]+-[0-9]+$/] and return true
        if verbose
          puts "#{Jira::Format.ticket(ticket)} is not a valid JIRA ticket."
        end
        return false
      end

      #
      # @return [Boolean] true if key file exists and is not empty
      #
      def key_exists?
        File.exists?(Jira::Core.key_path) && !File.zero?(Jira::Core.key_path)
      end

      #
      # @param text [String] string to encode
      # @return [String] encoded string
      #
      def encode(text)
        URI.escape(Base64.encode64(text))
      end

      #
      # @param text [String] string to dencode
      # @return [String] dencoded string
      #
      def decode(text)
        Base64.decode64(URI.unescape(text))
      end

      ### Relevant Paths

      #
      # @return [String] path to .jira-url file
      #
      def url_path
        @url_path ||= self.root_path + "/.jira-url"
      end

      #
      # @return [String] path to .jira-auth file
      #
      def auth_path
        @auth_path ||= self.root_path + "/.jira-auth"
      end

      #
      # @return [String] path to ~/.jira-key file
      #
      def key_path
        @key_path ||= ENV['HOME'] + "/.jira-key"
      end

      #
      # @return [String] path of root git directory
      #
      def root_path
        return @root_path if !@root_path.nil?
        raise GitException.new if !system('git rev-parse 2> /dev/null')
        @root_path ||= `git rev-parse --show-toplevel`.strip
      end

      protected

        #
        # Determines and parses the auth file
        #
        # @return [String] JIRA username
        # @return [String] JIRA password
        #
        def auth
          raise InstallationException if !self.key_exists?
          @auth ||= self.read(self.auth_path).split(':')
        end

        ### Core Actions

        #
        # Discards memozied class variables
        #
        def discard_memoized
          @url = nil
          @auth = nil
          @username = nil
          @password = nil
          @key = nil
        end

        #
        # Validates the location and reads the contents of the input path
        #
        # @param path [String] path of file to read
        #
        # @return [String] contents of the file at the input path
        #
        def read(path)
          self.validate_path!(path)
          File.read(path).strip
        end

        #
        # Aborts command if no file at the input path exists.
        #
        # @param path [String] path to validate
        #
        def validate_path!(path)
          raise InstallationException.new if !File.exists?(path)
        end

    end
  end
end
