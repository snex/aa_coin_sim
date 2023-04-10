require 'awesome_print'
require 'pry'
require 'random_variate_generator'
require_relative 'util'
require_relative 'agent_set'
require_relative 'auction'
require_relative 'vault'

class Sim
  ################ EDIT BELOW ###########################

  # total number of coins in existence
  # use the large number for the real sim. 1_000_000 is turned on for testing purposes
  #
  # AA_COINS = 1_000_000_000.freeze
  AA_COINS = 1_000_000.freeze

  # total amount of starting cash in pennies
  START_CASH = 100_000_000_000.freeze

  # amount of cash each agent starts with (randomize?)
  AGENT_STARTING_CASH = 100_000_000.freeze

  # odds that a given coin owned by an agent will be subject to a given action
  ACTIONS = {
    sell:     0.0001,
    reinvest: 0.35,
    stake:    0.65
  }.freeze

  # percentage of the total value of coins up for auction that buyers are willing to bid
  # likely will be replaced by a mean and a stddev for plugging into normal distribution
  BUY_PRESSURE = (0.005..0.05).freeze

  # when promise to buy is initiated, the mean number of coins to be promise-bought will be
  # 10% of the promise_to_buy_pool divided by the current coin price. this percentage will
  # then be added or subtracted randomly from that mean
  PROMISE_TO_BUY_PRESSURE = (-0.05..0.05).freeze

  # the number of weeks somebody can commit to in the future
  ACTION_WEEKS_MAX = 50.freeze

  # number of weeks to run the sim
  WEEKS_MAX = 100.freeze

  # percent of reward_pool to flow into aa_holding_pool each week
  REWARD_POOL_TO_AA_HOLDING_POOL_PERCENT = 0.01

  # percent of aa_holding_pool to flow into cash_vault each week
  AA_HOLDING_POOL_TO_CASH_VAULT_PERCENT = 0.01

  # percent of reward_pool to flow into promise_to_buy_pool each week
  REWARD_POOL_TO_PROMISE_TO_BUY_POOL_PERCENT = 0.01

  ################ DO NOT EDIT BELOW ####################

  def initialize
    @vault = Vault.new(AA_COINS.dup, START_CASH.dup)
    @agents = AgentSet.new
  end

  def run
    initiate_agents
    puts "created #{@agents.size} agents, running for #{WEEKS_MAX} weeks..."
    puts ''
    process_weeks
  end

  private

  def initiate_agents
    puts 'initiating agents...'

    coins_allocated = 0

    while coins_allocated < @vault.coins do
      coins_remaining = @vault.coins - coins_allocated
      coins_to_allocate = RandomVariateGenerator::Random.normal(mu: 0, sigma: 25_000).abs.to_i.clamp(1, coins_remaining)
      coins_allocated += coins_to_allocate

      @agents.add_agent(coins_to_allocate, AGENT_STARTING_CASH, ACTIONS)
    end
  end

  def process_weeks
    puts "#{@vault}"
    puts ''
    puts "running for #{WEEKS_MAX} weeks..."

    WEEKS_MAX.times do |week|
      process_week(week)
    end
  end

  def process_week(week)
    puts "week #{week + 1}"
    calculate_agent_actions(week)
    puts ''
    enact_agent_actions(week)
    puts ''
    puts "week #{week + 1} finished"
    puts ''
    puts @vault
    puts ''

    if @vault.coins == 0 || @vault.cash == 0
      puts "VAULT WENT TO ZERO!"
      exit
    end
  end

  def calculate_agent_actions(week)
    puts '..calculating agent actions'
    @agents.calculate_actions(week)
    puts '..agent actions calculated'
  end

  def enact_agent_actions(week)
    puts '..enacting agent actions'
    puts '....buying from holding_pool'
    demanded_coins = rand(0..@vault.coins(:holding_pool))

    demanded_coins.times do |i|
      premium = rand((0.01)..(0.1))
      buyer = @agents.get_random_agent

      # check for inf loops
      while buyer.cash.pennies < (@vault.coin_value + @vault.coin_value * premium)
        buyer = @agents.get_random_agent
      end

      buyer.buy_coins(@vault, premium)
    end

    puts '....buying from holding_pool complete'

    puts '....running auction'

    pre_auction_vault_cash = @vault.cash
    coins_at_auction = @agents.coins_at_auction(week)
    buyer_bid_amount = (rand(BUY_PRESSURE) * @vault.coin_value * coins_at_auction).to_i

    Auction.new(@vault, @agents, week).run_auction(coins_at_auction, buyer_bid_amount)

    buyer = @agents.add_agent(0, buyer_bid_amount, ACTIONS)
    @vault.xfer_cash(buyer.cash, :cash_vault, buyer_bid_amount)
    @vault.xfer_cash(:cash_vault, :reward_pool, @vault.cash - pre_auction_vault_cash)
    buyer.deposit_coins(@vault.coins - @agents.agents.map { |id, agent| agent.coins }.map(&:coins).sum)

    puts '....auction complete'
    enact_agent_sell_coins(week)
    puts '..agent actions completed'

    puts '..adjusting accounts'
    cash_to_aa_holding_pool = (@vault.cash(:reward_pool) * REWARD_POOL_TO_AA_HOLDING_POOL_PERCENT).round 
    cash_to_promise_to_buy_pool = (@vault.cash(:reward_pool) * REWARD_POOL_TO_PROMISE_TO_BUY_POOL_PERCENT).round
    @vault.xfer_cash(:reward_pool, :aa_holding_pool, cash_to_aa_holding_pool)
    @vault.xfer_cash(:reward_pool, :promise_to_buy_pool, cash_to_promise_to_buy_pool)
    @vault.xfer_cash(:aa_holding_pool, :cash_vault, (@vault.cash(:aa_holding_pool) * AA_HOLDING_POOL_TO_CASH_VAULT_PERCENT).round)
    puts '..adjusting accounts complete'
  end

  def enact_agent_sell_coins(week)
    puts '....selling coins'
    @agents.sell_coins(week, @vault)
    puts '....finished selling coins'
  end
end
