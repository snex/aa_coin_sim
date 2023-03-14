require_relative 'util'

class Auction
  def initialize(vault, agents, week)
    @vault = vault
    @agents = agents
    @week = week
  end

  def run_auction(coins_at_auction, buyer_bid_amount)
    pre_auction_coin_value = @vault.coin_value
    pennies_reinvested = pre_auction_coin_value * coins_at_auction
    total_bid_amount = pennies_reinvested + buyer_bid_amount

    @agents.agents.each do |id, agent|
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
  end
end
