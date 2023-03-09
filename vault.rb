require_relative 'util'

class Vault
  def initialize(coins, cash)
    @coin_accounts = {
      coin_vault:   CoinAccount.new(coins),
      holding_pool: CoinAccount.new(0)
    }
    @cash_accounts = {
      cash_vault:         CashAccount.new(cash),
      reward_pool:        CashAccount.new(0),
      # for the purpose of the sim, these can all be one giant bucket
      customer_payouts:   CashAccount.new(0),
      customer_purchases: CashAccount.new(Float::INFINITY)
    }
  end

  def coins(account = :coin_vault)
    @coin_accounts[account].coins
  end

  def cash(account = :cash_vault)
    @cash_accounts[account].pennies
  end

  def xfer_coins(debit_account, credit_account, coins)
    @coin_accounts[debit_account].debit(coins)
    @coin_accounts[credit_account].credit(coins)
    #puts "xfer #{print_number(coins)} from #{debit_account} to #{credit_account}"
  end

  def xfer_cash(debit_account, credit_account, pennies)
    @cash_accounts[debit_account].debit(pennies)
    @cash_accounts[credit_account].credit(pennies)
    #puts "xfer #{print_number(pennies)} from #{debit_account} to #{credit_account}"
  end

  def coin_value
    return 0 if @cash_accounts[:cash_vault].pennies.zero? || @coin_accounts[:coin_vault].coins.zero?
    @cash_accounts[:cash_vault].pennies / @coin_accounts[:coin_vault].coins
  end

  def total_coins
    @coin_accounts.values.map(&:coins).sum
  end

  def total_cash
    aa_cash_accounts.values.map(&:pennies).sum
  end

  def total_cash_dollars
    '%0.02f' % (total_cash / 100.0).round(2)
  end

  def to_s
    "Coin Accounts\n" +
    '=' * 45 + "\n" +
    @coin_accounts.map do |k,v|
      "#{k.to_s.rjust(20)}: #{v}\n"
    end.join +
    '=' * 45 + "\n" +
    "Total:".rjust(21) + "∀#{print_number(total_coins)}\n\n".rjust(26) +
    "AA Cash Accounts\n" +
    '=' * 45 + "\n" +
    aa_cash_accounts.map do |k,v|
      "#{k.to_s.rjust(20)}: #{v}\n"
    end.join +
    '=' * 45 + "\n" +
    "Total:".rjust(21) + "$#{print_number(total_cash_dollars)}\n\n".rjust(26) +
    "Customer Cash Accounts\n" +
    '=' * 45 + "\n" +
    customer_cash_accounts.map do |k,v|
      "#{k.to_s.rjust(20)}: #{v}\n"
    end.join + "\n" +
    "Coin Price:".rjust(21) + "$#{print_number(coin_value_dollars)}".rjust(24) + "/coin"
  end

  private

  def coin_value_dollars
    '%0.02f' % (coin_value / 100.0).round(2)
  end

  def customer_accounts
    [:customer_payouts, :customer_purchases]
  end

  def customer_cash_accounts
    @cash_accounts.select { |k,v| customer_accounts.include?(k) }
  end

  def aa_cash_accounts
    @cash_accounts.reject { |k,v| customer_accounts.include?(k) }
  end
end

class CoinAccount
  attr_reader :coins

  def initialize(coins)
    @coins = coins
  end

  def credit(coins)
    @coins += coins
  end

  def debit(coins)
    @coins -= coins
  end

  def to_s
    "∀#{print_number(@coins)}".rjust(23)
  end
end

class CashAccount
  attr_reader :pennies

  def initialize(pennies)
    @pennies = pennies
  end

  def credit(pennies)
    @pennies += pennies
  end

  def debit(pennies)
    @pennies -= pennies
  end

  def dollars
    '%0.02f' % (@pennies / 100.0).round(2)
  end

  def to_s
    "$#{print_number(dollars)}".rjust(23)
  end
end
