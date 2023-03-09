require_relative 'util'

class Agent
  attr_reader :coins, :action_table

  def initialize(coins, action_odds, vault)
    @coins = coins
    @action_odds = action_odds
    @vault = vault
    @action_table = {
      coins_to_sell: {},
      coins_to_reinvest: {},
      coins_to_buy: {}
    }
  end

  def deposit_coins(coins)
    @coins += coins
  end

  def remove_coins(coins)
    @coins -= coins
  end

  def calculate_actions(week)
    coins_to_sell, coins_to_reinvest, coins_to_stake = get_randoms_summing_to(@coins, @action_odds.size, @action_odds.values)
    coins_to_buy = 0 # something??

    @action_table[:coins_to_sell][week] = coins_to_sell
    @action_table[:coins_to_reinvest][week] = coins_to_reinvest
    @action_table[:coins_to_buy][week] = coins_to_buy
  end

  def sell_coins(week, semaphore = nil)
    coins_to_sell = @action_table[:coins_to_sell][week]
    remove_coins(coins_to_sell)
    @action_table[:coins_to_sell][week] = 0
    sell_amt = (coins_to_sell * @vault.coin_value).to_i
    amt_to_customer = (sell_amt * (1 - sell_penalty(0))).to_i
    amt_to_reward_pool = sell_amt - amt_to_customer

    semaphore.lock if semaphore
    @vault.xfer_cash(:cash_vault, :customer_payouts, amt_to_customer)
    @vault.xfer_cash(:cash_vault, :reward_pool, amt_to_reward_pool)
    @vault.xfer_coins(:coin_vault, :holding_pool, coins_to_sell)
    semaphore.unlock if semaphore
  end
end
