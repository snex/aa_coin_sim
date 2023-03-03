AA_COINS = 1_000_000_000.freeze

# odds that a given coin owned by an agent will be subject to a given action
ACTIONS = {
  sell:     0.05,
  stake:    0.75,
  reinvest: 0.20
}.freeze

# the number of weeks somebody can commit to in the future
ACTION_WEEKS_MAX = 50.freeze

# number of weeks to run the sim
WEEKS_MAX = 100.freeze

################ DO NOT EDIT BELOW #####################

require 'awesome_print'
require 'pry'
require 'random_variate_generator'
require_relative 'util'
require_relative 'agent'

def coin_value_in_dollars(pennies)
  '%0.02f' % ((pennies / 100.0) / AA_COINS).round(2)
end

agents = []
coins_allocated = 0
pennies = 100_000_000_000
risk_pool = 0
reward_pool = 0
owner_pool = 0
promise_buy_pool = 0

puts "initiating agents..."

while coins_allocated < AA_COINS do
  coins_remaining = AA_COINS - coins_allocated
  coins_to_allocate = RandomVariateGenerator::Random.normal(mu: 0, sigma: 25_000).abs.to_i.clamp(1, coins_remaining)
  coins_allocated += coins_to_allocate

  agents.push(Agent.new(coins_to_allocate, ACTIONS))
end

puts "#{agents.size} agents initiated"
puts ""
puts "running for #{WEEKS_MAX} weeks..."

WEEKS_MAX.times do |week|
  puts "week #{week}"
  puts "..calculating agent actions"
  threads = []

  agents.each_with_index do |agent, i|
    threads << Thread.new do
      agent.calculate_actions(week)
    end
  end

  threads.map(&:join)

  puts "..agent actions calculated"
  puts "..enacting agent actions"
  threads = []

  agents.each do |agent|
    threads << Thread.new do
      agent.sell_coins(week)
    end
  end

  pennies += threads.map(&:value).sum

  puts "week #{week} finished"
  puts "dollars in vault: #{(pennies / 100.0).round(2)}"
  puts "AA Coin value: #{coin_value_in_dollars(pennies)}"
  puts ""
end

puts "results:"
puts ""
