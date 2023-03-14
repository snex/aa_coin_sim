require_relative 'util'

class Auction
  def initialize(vault, agents, week)
    @vault = vault
    @agents = agents
    @week = week
  end

  # buyer bid amount will probably come from a set of objects rather than a param, but have it here for now
  def run_auction(buy_pressure)
    pre_auction_vault_cash = @vault.cash
    pre_auction_coin_value = @vault.coin_value

    coins_at_auction = @agents.map { |agent| agent.action_table[:coins_to_reinvest][@week] }.sum
    buyer_bid_amount = (buy_pressure * pre_auction_coin_value * coins_at_auction).to_i

    buyer = Agent.new(0, buyer_bid_amount, Sim::ACTIONS, @vault)

    pennies_reinvested = pre_auction_coin_value * coins_at_auction
    total_bid_amount = pennies_reinvested + buyer_bid_amount

    @agents.each do |agent|
      coins_reinvested = agent.action_table[:coins_to_reinvest][@week]
      agent.remove_coins(coins_reinvested)
      coins_reinvested_value = coins_reinvested * pre_auction_coin_value
      agent_percent = (coins_reinvested_value).to_f / total_bid_amount

      # do some fancy math to ensure that total coin amount never changes
      reinvested_coins_returned = (agent_percent * coins_at_auction).round
      reinvested_coins_returned_value = reinvested_coins_returned * pre_auction_coin_value
      payout_value = coins_reinvested_value - reinvested_coins_returned_value

      agent.action_table[:coins_to_reinvest][@week] = 0
      agent.deposit_coins(reinvested_coins_returned)
      @vault.xfer_cash(:cash_vault, agent.cash, payout_value)

      # make sure these all add up to total vault coins
      new_rei_tokens = coins_reinvested * (@vault.total_coins.to_f / coins_at_auction.to_f).round
      agent.deposit_rei_tokens(new_rei_tokens)
    end

    @agents.push(buyer)
    @vault.xfer_cash(buyer.cash, :cash_vault, buyer_bid_amount)
    @vault.xfer_cash(:cash_vault, :reward_pool, @vault.cash - pre_auction_vault_cash)
    buyer.deposit_coins(@vault.coins - @agents.map(&:coins).map(&:coins).sum)
    buyer
  end
end
