require_relative 'util'

class Agent
  attr_reader :coins, :cash, :rei_tokens, :action_table

  def initialize(coins, cash, action_odds, vault)
    @coins = CoinAccount.new(coins)
    @cash = CashAccount.new(cash)
    @rei_tokens = REIAccount.new(0)
    @action_odds = action_odds
    @vault = vault
    @action_table = {
      coins_to_sell: {},
      coins_to_reinvest: {},
      coins_to_buy: {}
    }
  end

  def deposit_coins(coins)
    @coins.credit(coins)
  end

  def remove_coins(coins)
    @coins.debit(coins)
  end

  def deposit_rei_tokens(tokens)
    @rei_tokens.credit(tokens)
  end

  def remove_rei_tokens(tokens)
    @rei_tolens.debit(tokens)
  end

  def calculate_actions(week)
    coins_to_sell, coins_to_reinvest, coins_to_stake = get_randoms_summing_to(@coins.coins, @action_odds.size, @action_odds.values)
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
    amt_to_vault = sell_amt - amt_to_customer
    # make sure this adds up!
    amt_to_reward_pool = amt_to_reinvest_pool = amt_to_vault.to_f / 2

    semaphore.lock if semaphore
    @vault.xfer_cash(:cash_vault, @cash, amt_to_customer)
    @vault.xfer_cash(:cash_vault, :reward_pool, amt_to_reward_pool)
    @vault.xfer_cash(:cash_vault, :reinvest_pool, amt_to_reinvest_pool)
    @vault.xfer_coins(:coin_vault, :holding_pool, coins_to_sell)
    semaphore.unlock if semaphore
  end

  def to_s
    %{#{'=' * 45}
#{'Coins:'.rjust(21)} #{@coins.to_s.rjust(23)}
#{'Cash:'.rjust(21)} #{@cash.to_s.rjust(23)}
#{'REI Tokens:'.rjust(21)} #{@rei_tokens.to_s.rjust(23)}
    }
  end
end
