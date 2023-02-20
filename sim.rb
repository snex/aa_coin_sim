AA_COINS = 1_000_000_000
DOLLARS = 10_000_000

ACTIONS = {
  (0..(0.25)) =>      :sell,
  ((0.25)...(0.5)) => :stake,
  ((0.5)...(0.75)) => :reinvest,
  ((0.75)...1) =>     :buy
}

# the number of weeks somebody can commit to in the future
ACTION_WEEKS_MAX = 50

# number of weeks to run the sim
WEEKS_MAX = 100

################ DO NOT EDIT BELOW #####################

require 'awesome_print'
require 'pry'
require 'random_variate_generator'

def get_randoms_summing_to(target_sum, num_randoms)
  denormalized = []
  orig_num_randoms = num_randoms

  if num_randoms > target_sum
    num_randoms = target_sum
  end

  while denormalized.sum != target_sum do
    normalized = []
    denormalized.clear
    num_randoms.times do
      normalized.push(rand)
    end

    normalized_sum = normalized.sum
    denormalized = normalized.map { |n| (target_sum * (n / normalized_sum)).round }
  end

  if orig_num_randoms != num_randoms
    return (denormalized + Array.new(orig_num_randoms - num_randoms, 0)).shuffle
  end

  denormalized
end

def sell_penalty(weeks)
  10 * ((1 / 1.0471285481) ** weeks)
end

agents = []
coins_allocated = 0
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
    coins_to_sell, coins_to_stake, coins_to_reinvest, coins_to_buy = get_randoms_summing_to(agent_coins, ACTIONS.size)
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
  puts "week #{week} finished"
  puts ""
end

puts "results:"
puts ""
