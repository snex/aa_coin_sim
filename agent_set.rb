require 'securerandom'
require_relative 'agent'

class AgentSet
  include Enumerable

  attr_reader :agents

  def initialize
    @agents = {}
  end

  def each(&block)
    @agents.each(&block)
  end

  def size
    @agents.size
  end

  def add_agent(coins, cash, action_odds, vault)
    new_id = SecureRandom.uuid
    @agents[new_id] = Agent.new(coins, cash, action_odds, vault)
  end

  def to_s
    @agents.map do |id, agent|
      %{Agent #{id}
#{'=' * 45}
#{agent}}
    end.join("\n")
  end
end
