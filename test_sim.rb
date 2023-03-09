require 'random_variate_generator'
require_relative 'util'
require_relative 'agent'
require_relative 'auction'
require_relative 'vault'

class TestSim
  def initialize
  end

  def run
    AuctionSim.new.run
    puts ''
    SellSim.new.run
  end

  class SellSim
    def initialize
      @vault = Vault.new(100, 100)
      @agents = [
        Agent.new(100, { sell: 1, reinvest: 0, stake: 0 }, @vault)
      ]
    end

    def run
      run_sell_test
    end

    private

    def run_sell_test
      puts "RUNNING SELL TEST"
      puts ''
      puts @vault
      puts ''
      @agents.each { |a| a.calculate_actions(0) }
      @agents.each { |a| a.sell_coins(0) }
      puts "Agent Coins"
      puts @agents.map { |a| a.coins }.inspect
      puts ''
      puts @vault

      puts ''
      puts 'agents should have the following in their coin accounts'
      puts '0'
      puts 'and the following in their cash accounts'
      puts '$0.90 (currently all customer payouts are in 1 bucket called customer_payouts)'
      puts ''
      puts 'holding pool should have 100 coins'
      puts 'reward pool should have $0.10'
      puts ''
      puts 'FINISHED SELL TEST'
    end
  end

  class AuctionSim
    def initialize
      @vault = Vault.new(450, 4_500)
      @agents = [
        Agent.new(150, { sell: 0, reinvest: 1, stake: 0 }, @vault),
        Agent.new(100, { sell: 0, reinvest: 1, stake: 0 }, @vault),
        Agent.new(200, { sell: 0, reinvest: 1, stake: 0 }, @vault),
      ]
    end

    def run
      run_auction_test
    end

    private

    def run_auction_test
      puts "RUNNING AUCTION TEST"
      puts ''
      puts @vault
      puts ''
      @agents.each { |a| a.calculate_actions(0) }
      Auction.new(@vault, @agents, 0).run_auction(500)
      puts "Agent Coins"
      puts @agents.map { |a| a.coins }.inspect
      puts ''
      puts @vault

      puts ''
      puts 'agents should have the following in their coin accounts'
      puts '135, 90, 180'
      puts 'and the following in their cash accounts'
      puts '$1.50, $1.00, $2.00 (currently all customer payouts are in 1 bucket called customer_payouts)'
      puts ''
      puts 'reward pool should have $0.50'
      puts ''
      puts 'FINISHED AUCTION TEST'
    end
  end
end
