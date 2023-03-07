require 'awesome_print'
require 'pry'
require 'random_variate_generator'
require_relative 'util'
require_relative 'agent'
require_relative 'auction'

class Sim
  ################ EDIT BELOW ###########################

  # total number of coins in existence
  # use the large number for the real sim. 1_000 is turned on for testing purposes
  # AA_COINS = 1_000_000_000.freeze
  AA_COINS = 1_000_000.freeze

  # odds that a given coin owned by an agent will be subject to a given action
  ACTIONS = {
    sell:     0.0001,
    reinvest: 0.35,
    stake:    0.65
  }.freeze

  # the number of weeks somebody can commit to in the future
  ACTION_WEEKS_MAX = 50.freeze

  # number of weeks to run the sim
  WEEKS_MAX = 2.freeze

  ################ DO NOT EDIT BELOW ####################

  def initialize
    # coin accounts
    @vault = AA_COINS.dup
    @coins_allocated_to_users = 0
    @holding_pool = 0

    # cash accounts
    @pennies_in_vault = 100_000_000_000
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

  def dollars_in_vault
    '%0.02f' % (@pennies_in_vault / 100.0).round(2)
  end

  def coin_value_in_pennies
    (@pennies_in_vault / AA_COINS).round(0)
  end

  def coin_value_in_dollars
    '%0.02f' % (coin_value_in_pennies / 100.0).round(2)
  end

  def initiate_agents
    puts 'initiating agents...'

    while @coins_allocated_to_users < @vault do
      coins_remaining = @vault - @coins_allocated_to_users
      coins_to_allocate = RandomVariateGenerator::Random.normal(mu: 0, sigma: 25_000).abs.to_i.clamp(1, coins_remaining)
      @coins_allocated_to_users += coins_to_allocate

      @agents.push(Agent.new(coins_to_allocate, ACTIONS))
    end

    puts "#{@agents.size} agents initiated"
  end

  def process_weeks
    puts "dollars in vault: #{print_money(dollars_in_vault)}"
    puts "AA Coin value: #{print_money(coin_value_in_dollars)}"
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
    puts "..coins in vault: #{print_number(@vault)}"
    puts "..coins in holding pool: #{print_number(@holding_pool)}"
    puts "..dollars in vault: #{print_money(dollars_in_vault)}"
    puts "..dollars in reward pool: #{print_money(@reward_pool / 100.0)}"
    puts "..AA Coin value: #{print_money(coin_value_in_dollars)}"
    puts "week #{week + 1} finished"
    puts ''

    if @vault == 0
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
    pre_auction_vault = @pennies_in_vault
    pennies_paid_out = Auction.new(coin_value_in_pennies, @agents, week).run_auction
    @pennies_in_vault -= pennies_paid_out
    reward_pool_payout = @pennies_in_vault - pre_auction_vault
    @pennies_in_vault -= reward_pool_payout
    @reward_pool += reward_pool_payout
    puts "pennies_in_vault: #{print_money(@pennies_in_vault / 100.0)}"

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
    @pennies_in_vault += coins_sold * coin_value_in_pennies * sell_penalty(0)
    @vault -= coins_sold
    @holding_pool += coins_sold
  end
end
