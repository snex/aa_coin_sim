require 'awesome_print'
require 'pry'
require 'random_variate_generator'
require_relative 'util'
require_relative 'agent'
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
  START_CASH = 100_000_000.freeze

  # odds that a given coin owned by an agent will be subject to a given action
  ACTIONS = {
    sell:     0.0001,
    reinvest: 0.35,
    stake:    0.65
  }.freeze

  # the number of weeks somebody can commit to in the future
  ACTION_WEEKS_MAX = 50.freeze

  # number of weeks to run the sim
  WEEKS_MAX = 100.freeze

  ################ DO NOT EDIT BELOW ####################

  def initialize
    @vault = Vault.new(AA_COINS.dup, START_CASH.dup)

    # coin accounts
    @holding_pool = 0

    # cash accounts
    @reward_pool = 0

    @agents = []
  end

  def run
    initiate_agents
    puts ''
    process_weeks
  end

  private

  def sell_penalty(weeks)
    10 * ((1 / 1.0471285481) ** weeks)
  end

  def initiate_agents
    puts 'initiating agents...'

    coins_allocated = 0

    while coins_allocated < @vault.coins do
      coins_remaining = @vault.coins - coins_allocated
      coins_to_allocate = RandomVariateGenerator::Random.normal(mu: 0, sigma: 25_000).abs.to_i.clamp(1, coins_remaining)
      coins_allocated += coins_to_allocate

      @agents.push(Agent.new(coins_to_allocate, ACTIONS))
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
    puts "..vault: #{@vault}"
    puts "..coins in holding pool: #{print_number(@holding_pool)}"
    puts "..dollars in reward pool: $#{print_number('%0.02f' % (@reward_pool / 100.0).round(2))}"
    puts "week #{week + 1} finished"
    puts ''

    if @vault.coins == 0 || @vault.cash == 0
      puts "VAULT WENT TO ZERO!"
      exit
    end
  end

  def calculate_agent_actions(week)
    puts '..calculating agent actions'
    threads = []

    @agents.each_with_index do |agent, i|
      threads << Thread.new do
        agent.calculate_actions(week)
      end
    end

    threads.map(&:join)

    puts '..agent actions calculated'
  end

  def enact_agent_actions(week)
    puts '..enacting agent actions'
    puts '....running auction'
    pre_auction_vault = @vault.cash
    pennies_paid_out = Auction.new(@vault, @agents, week).run_auction
    reward_pool_payout = @vault.cash - pre_auction_vault
    @vault.debit_cash(reward_pool_payout)
    @reward_pool += reward_pool_payout

    puts '....selling coins'
    enact_agent_sell_coins(week)

    puts '..agent actions completed'
  end

  def enact_agent_sell_coins(week)
    threads = []

    @agents.each do |agent|
      threads << Thread.new do
        agent.sell_coins(week)
      end
    end

    coins_sold = threads.map { |t| t.value }.sum
    @vault.credit_cash(coins_sold * @vault.coin_value * sell_penalty(0))
    @vault.debit_coins(coins_sold)
    @holding_pool += coins_sold
  end
end
