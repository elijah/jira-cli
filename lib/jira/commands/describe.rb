module Jira
  class CLI < Thor

    desc "describe", "Describes the input ticket"
    def describe(ticket=Jira::Core.ticket)
      if Jira::Core.ticket?(ticket)
        output = description(ticket.strip, false, true, true)
        puts output if !output.strip.empty?
      end
    end

    desc "all", "Describes all local branches that match JIRA ticketing syntax"
    def all
      # determine which local branches match JIRA ticket syntax
      #   TODO - move to Jira::Git
      tickets = {
        current: nil,
        others: []
      }
      branches = `git branch`.strip.split("\n")
      branches.each do |branch|
        ticket = branch.delete('*').strip
        if Jira::Core.ticket?(ticket, false)
          if branch.include?('*')
            tickets[:current] = ticket
          else
            tickets[:others] << ticket
          end
        end
      end


      # asynchronously fetch and describe tickets
      output = ""
      threads = []
      if !tickets[:current].nil?
        threads << Thread.new{ puts description(tickets[:current], true) }
      end
      mutex = Mutex.new
      tickets[:others].each do |ticket|
        threads << Thread.new do
          out = description(ticket) + "\n"
          if !out.strip.empty?
            mutex.synchronize{ output << out }
          end
        end
      end
      threads.each{ |thread| thread.join }
      puts output if !output.empty?
    end

    protected

      #
      # Returns a formatted description of the input ticket
      #
      # @param ticket [String] the ticket to describe
      # @param star [Boolean] if true, adds a * indicator
      #
      # @return [String] formatted summary string
      #
      def description(ticket, star=false, verbose=false, describe=false)
        self.api.get("issue/#{ticket}", nil, verbose) do |json|
          summary = json['fields']['summary']
          status = json['fields']['status']['name']
          assignee = json['fields']['assignee']['name']
          description = describe ? "\n" + json['fields']['description'].to_s : ""

          return Jira::Format.ticket(ticket) +
                (star ? Jira::Format.star : " ") + "  " +
                ("(" + Jira::Format.user(assignee) + ")").ljust(20) +
                Jira::Format.status(status).ljust(26) +
                Jira::Format.summary(summary) +
                description
        end
        return ""
      end

  end
end
