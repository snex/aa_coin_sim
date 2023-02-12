aa_coins = 1_000_000_000
dollars = 10_000_000
risk_pool = 0
reward_pool = 0
owner_pool = 0
promise_buy_pool = 0

actions = {
  (0..(0.25)) =>      :sell,
  ((0.25)...(0.5)) => :stake,
  ((0.5)...(0.75)) => :reinvest,
  ((0.75)...1) =>     :buy
}

################

require 'awesome_print'
require 'random_variate_generator'

agents = []
coins_allocated = 0

while coins_allocated < aa_coins do
  coins_remaining = aa_coins - coins_allocated
  coins_to_allocate = RandomVariateGenerator::Random.normal(mu: 0, sigma: 25_000).abs.to_i.clamp(1, coins_remaining)
  coins_allocated += coins_to_allocate

  agents.push({
    coins: coins_to_allocate
  })
end

100.times do |week|
  puts "week #{week}"
  agents.each_with_index do |agent, i|
    r = rand
    action = actions.select { |k,v| k.include?(r) }.values.first

    case action
    when :sell
      #puts '----sell'
    when :stake
      #puts '----stake'
    when :reinvest
      #puts '----reinvest'
    when :buy
      #puts '---buy'
    else
      raise 'wtf?'
    end
  end
end
