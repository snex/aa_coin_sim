require 'random_variate_generator'
require_relative 'util'
require_relative 'agent'
require_relative 'auction'
require_relative 'vault'

class TestSim
  def initialize
    @vault = Vault.new(450, 4_500)
    @agents = [
      Agent.new(150, { sell: 0, reinvest: 1, stake: 0 }),
      Agent.new(100, { sell: 0, reinvest: 1, stake: 0 }),
      Agent.new(200, { sell: 0, reinvest: 1, stake: 0 }),
    ]
  end

  def run
    puts @vault
    puts ''
    @agents.each { |a| a.calculate_actions(0) }
    Auction.new(@vault, @agents, 0).run_auction(500)
    puts "Agent Coins"
    puts @agents.map { |a| a.coins }.inspect
    puts ''
    puts @vault

    # agents should have the following in their coin accounts
    # 135, 90, 180
    # and the following in their cash accounts
    # $1.50, $1.00, $2.00
    # reward pool should have $0.50
  end
end
