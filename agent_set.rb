require 'securerandom'
require_relative 'agent'

class AgentSet
  attr_reader :agents

  def initialize
    @agents = {}
  end

  def size
    @agents.size
  end

  def get_random_agent
    @agents[@agents.keys.sample]
  end

  def add_agent(coins, cash, action_odds)
    new_id = SecureRandom.uuid
    @agents[new_id] = Agent.new(coins, cash, action_odds)
  end

  def calculate_actions(week)
    threads = []

    @agents.each do |id, agent|
      threads << Thread.new do
        agent.calculate_actions(week)
      end
    end

    threads.map(&:join)
  end

  def coins_at_auction(week)
    threads = []

    @agents.map do |id, agent|
      threads << Thread.new do
        agent.action_table[:coins_to_reinvest][week]
      end
    end

    threads.map(&:value).sum
  end

  def sell_coins(week, vault)
    semaphore = Thread::Mutex.new
    threads = []

    @agents.each do |id, agent|
      threads << Thread.new do
        agent.sell_coins(week, vault, semaphore)
      end
    end

    threads.map(&:join)
  end

  def to_s(vault)
    @agents.map do |id, agent|
      %{Agent #{id}
#{'=' * 45}
#{agent.to_s(vault)}}
    end.join("\n")
  end
end
