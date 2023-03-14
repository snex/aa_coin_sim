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
  START_CASH = 100_000_000_000.freeze

  # odds that a given coin owned by an agent will be subject to a given action
  ACTIONS = {
    sell:     0.0001,
    reinvest: 0.35,
    stake:    0.65
  }.freeze

  BUY_PRESSURE = (0.005..0.05).freeze

  # the number of weeks somebody can commit to in the future
  ACTION_WEEKS_MAX = 50.freeze

  # number of weeks to run the sim
  WEEKS_MAX = 100.freeze

  ################ DO NOT EDIT BELOW ####################

  def initialize
    @vault = Vault.new(AA_COINS.dup, START_CASH.dup)
    @agents = []
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

      @agents.push(Agent.new(coins_to_allocate, 0, ACTIONS, @vault))
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
    buyer = Auction.new(@vault, @agents, week).run_auction(rand(BUY_PRESSURE))
    buyer.calculate_actions(week)
    puts '....auction complete'
    enact_agent_sell_coins(week)
    puts '..agent actions completed'
  end

  def enact_agent_sell_coins(week)
    puts '....selling coins'
    semaphore = Thread::Mutex.new
    threads = []

    @agents.each do |agent|
      threads << Thread.new do
        agent.sell_coins(week, semaphore)
      end
    end

    threads.map(&:join)
    puts '....finished selling coins'
  end
end
