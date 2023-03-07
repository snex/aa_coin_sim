require_relative 'util'

class Agent
  attr_reader :coins, :action_table

  def initialize(coins, action_odds)
    @coins = coins
    @action_odds = action_odds
    @action_table = {
      coins_to_sell: {},
      coins_to_reinvest: {},
      coins_to_buy: {}
    }
  end

  def deposit_coins(coins)
    @coins += coins
  end

  def calculate_actions(week)
    coins_to_sell, coins_to_reinvest, coins_to_stake = get_randoms_summing_to(@coins, @action_odds.size, @action_odds.values)
    coins_to_buy = 0 # something??

    @action_table[:coins_to_sell][week] = coins_to_sell
    @action_table[:coins_to_reinvest][week] = coins_to_reinvest
    @action_table[:coins_to_buy][week] = coins_to_buy
  end

  def sell_coins(week)
    coins_to_sell = @action_table[:coins_to_sell][week]
    @coins -= coins_to_sell
    @action_table[:coins_to_sell][week] = 0
    coins_to_sell
  end
end
