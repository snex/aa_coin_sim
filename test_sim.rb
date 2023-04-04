require 'random_variate_generator'
require_relative 'util'
require_relative 'agent'
require_relative 'auction'
require_relative 'vault'

class TestSim
  def initialize
  end

  def run
    BuySim.new.run
    puts ''
    AuctionSim.new.run
    puts ''
    SellSim.new.run
  end

  class BuySim
    def initialize
      @vault = Vault.new(101, 10_000)
      @vault.xfer_coins(:coin_vault, :holding_pool, 1)
      @agents = AgentSet.new
      @agents.add_agent(100, 110, [])
    end

    def run
      run_buy_test
    end

    private

    def run_buy_test
      puts "RUNNING BUY TEST"
      puts ''
      puts @vault
      puts ''
      @agents.get_random_agent.buy_coins(@vault, 0.10)
      puts @agents
      puts ''
      puts @vault
      puts ''
      puts 'agents should have the following in their coin accounts'
      puts '101'
      puts 'and the following in their cash accounts'
      puts '$0.00'
      puts ''
      puts 'coin_vault should have 101 coins'
      puts 'holding pool should have 0 coins'
      puts 'cash_vault should have $101.00'
      puts 'reward pool should have $0.10'
      puts 'reinvest pool should have $0.00'
      puts ''
      puts 'FINISHED BUY TEST'
    end
  end

  class SellSim
    def initialize
      @vault = Vault.new(100, 100)
      @agents = AgentSet.new
      @agents.add_agent(100, 0, { sell: 1, reinvest: 0, stake: 0 })
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
      @agents.calculate_actions(0)
      @agents.sell_coins(0, @vault)
      puts @agents
      puts ''
      puts @vault
      puts ''
      puts 'agents should have the following in their coin accounts'
      puts '0'
      puts 'and the following in their cash accounts'
      puts '$0.90'
      puts ''
      puts 'holding pool should have 100 coins'
      puts 'reward pool should have $0.05'
      puts 'reinvest pool should have $0.05'
      puts ''
      puts 'FINISHED SELL TEST'
    end
  end

  class AuctionSim
    def initialize
      @vault = Vault.new(450, 4_500)
      @agents = AgentSet.new
      @agents.add_agent(150, 0, { sell: 0, reinvest: 1, stake: 0 })
      @agents.add_agent(100, 0, { sell: 0, reinvest: 1, stake: 0 })
      @agents.add_agent(200, 0, { sell: 0, reinvest: 1, stake: 0 })
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
      @agents.calculate_actions(0)

      Auction.new(@vault, @agents, 0).run_auction(450, 500)

      buyer = @agents.add_agent(0, 500, {})
      @vault.xfer_cash(buyer.cash, :cash_vault, 500)
      @vault.xfer_cash(:cash_vault, :reward_pool, 50)
      buyer.deposit_coins(45)

      puts @agents
      puts ''
      puts @vault
      puts ''
      puts 'agents should have the following in their coin accounts'
      puts '135, 90, 180, 45'
      puts 'and the following in their cash accounts'
      puts '$1.50, $1.00, $2.00, $0.00'
      puts 'and the following in their rei_token accounts'
      puts '150, 100, 200, 0'
      puts ''
      puts 'reward pool should have $0.50'
      puts ''
      puts 'FINISHED AUCTION TEST'
    end
  end
end
