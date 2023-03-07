require_relative 'util'

class Auction
  def initialize(vault_price, agents, week)
    @vault_price = vault_price
    @agents = agents
    @week = week
  end

  def run_auction
    value_to_remove_from_vault = 0
    coins_at_auction = @agents.map { |agent| agent.action_table[:coins_to_reinvest][@week] }.sum
    puts "auctioning off #{print_number(coins_at_auction)} coins at #{print_number(@vault_price)} pennies"

    bid_amount = 0
    total_bid_in_pennies = @vault_price + bid_amount
    pennies_reinvested = @vault_price * coins_at_auction
    total_auction_price = total_bid_in_pennies + pennies_reinvested

    puts "total_bid_in_pennies: #{print_money(total_bid_in_pennies / 100.0)}"
    puts "pennies_reinvested: #{print_money(pennies_reinvested / 100.0)}"
    puts "total_auction_price: #{print_money(total_auction_price / 100.0)}"

    @agents.each do |agent|
      coins_reinvested = agent.action_table[:coins_to_reinvest][@week]
      coins_reinvested_value = coins_reinvested * @vault_price
      agent_percent = (coins_reinvested_value).to_f / total_auction_price
      reinvested_coins_returned = agent_percent * coins_at_auction
      reinvested_coins_returned_value = reinvested_coins_returned * @vault_price

      payout_value = coins_reinvested_value - reinvested_coins_returned_value
      value_to_remove_from_vault += payout_value
      puts "payout value #{print_money((payout_value / 100.0).round(2))}"

      agent.action_table[:coins_to_reinvest][@week] = 0
      agent.deposit_coins(agent_percent * coins_at_auction)
    end

    value_to_remove_from_vault - total_bid_in_pennies
  end
end
