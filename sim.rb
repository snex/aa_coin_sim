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

def sell_penalty(weeks)
  10 * ((1 / 1.0471285481) ** weeks)
end

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

  agents.push({
    coins: coins_to_allocate,
    coins_to_sell: Hash[Array.new(WEEKS_MAX).each_with_index.map { |x, i| [i, 0] }],
    coins_to_stake: Hash[Array.new(WEEKS_MAX).each_with_index.map { |x, i| [i, 0] }],
    coins_to_reinvest: Hash[Array.new(WEEKS_MAX).each_with_index.map { |x, i| [i, 0] }],
    coins_to_buy: Hash[Array.new(WEEKS_MAX).each_with_index.map { |x, i| [i, 0] }]
  })
end

puts "#{agents.size} agents initiated"
puts ""
puts "running for #{WEEKS_MAX} weeks..."

WEEKS_MAX.times do |week|
  puts "week #{week}"
  puts "..calculating agent actions"

  agents.each_with_index do |agent, i|
    agent_coins = agent[:coins]
    coins_to_sell, coins_to_stake, coins_to_reinvest = get_randoms_summing_to(agent_coins, ACTIONS.size, ACTIONS.values)
    coins_to_buy = 0 # something??

    sell_per_week = get_randoms_summing_to(coins_to_sell, ACTION_WEEKS_MAX)
    buy_per_week = get_randoms_summing_to(coins_to_buy, ACTION_WEEKS_MAX)

    sell_per_week.each_with_index do |c, i|
      next if i + week >= WEEKS_MAX
      agent[:coins_to_sell][i + week] += c
    end

    buy_per_week.each_with_index do |c, i|
      next if i + week >= WEEKS_MAX
      agent[:coins_to_buy][i + week] += c
    end
  end

  puts "..agent actions calculated"
  puts "..enacting agent actions"

  agents.each do |agent|
    coins_allocated -= agent[:coins_to_sell][week]
    pennies += agent[:coins_to_sell][week]
    agent[:coins_to_sell][week] = 0
  end

  puts "week #{week} finished"
  puts "dollars in vault: #{(pennies / 100.0).round(2)}"
  puts "AA Coin value: #{coin_value_in_dollars(pennies)}"
  puts ""
end

puts "results:"
puts ""
