AA_COINS = 1_000_000_000
DOLLARS = 10_000_000

ACTIONS = {
  (0..(0.25)) =>      :sell,
  ((0.25)...(0.5)) => :stake,
  ((0.5)...(0.75)) => :reinvest,
  ((0.75)...1) =>     :buy
}

################

require 'awesome_print'
require 'random_variate_generator'

def get_randoms_summing_to(target_sum, num_randoms)
  denormalized = []

  while denormalized.sum != target_sum do
    normalized = []
    denormalized.clear
    num_randoms.times do
      normalized.push(rand)
    end

    normalized_sum = normalized.sum
    denormalized = normalized.map { |n| (target_sum * (n / normalized_sum)).round }
  end

  denormalized
end

agents = []
coins_allocated = 0
risk_pool = 0
reward_pool = 0
owner_pool = 0
promise_buy_pool = 0

while coins_allocated < AA_COINS do
  coins_remaining = AA_COINS - coins_allocated
  coins_to_allocate = RandomVariateGenerator::Random.normal(mu: 0, sigma: 25_000).abs.to_i.clamp(1, coins_remaining)
  coins_allocated += coins_to_allocate

  agents.push({
    coins: coins_to_allocate
  })
end

100.times do |week|
  puts "week #{week}"
  agents.each_with_index do |agent, i|
    agent_coins = agent[:coins]
    coins_to_sell, coins_to_stake, coins_to_reinvest, coins_to_buy = get_randoms_summing_to(agent_coins, ACTIONS.size)

    agent[:coins_to_sell] = {}
    agent[:coins_to_stake] = {}
    agent[:coins_to_reinvest] = {}
    agent[:coins_to_buy] = {}
  end
end
