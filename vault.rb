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
      reinvest_pool:      CashAccount.new(0)
    }
  end

  def coins(account = :coin_vault)
    @coin_accounts[account].coins
  end

  def cash(account = :cash_vault)
    @cash_accounts[account].pennies
  end

  def xfer_coins(debit_account, credit_account, coins)
    if debit_account.is_a?(Symbol)
      @coin_accounts[debit_account].debit(coins)
    else
      debit_account.debit(coins)
    end

    if credit_account.is_a?(Symbol)
      @coin_accounts[credit_account].credit(coins)
    else
      credit_account.credit(coins)
    end
    #puts "xfer #{print_number(coins)} from #{debit_account} to #{credit_account}"
  end

  def xfer_cash(debit_account, credit_account, pennies)
    if debit_account.is_a?(Symbol)
      @cash_accounts[debit_account].debit(pennies)
    else
      debit_account.debit(pennies)
    end

    if credit_account.is_a?(Symbol)
      @cash_accounts[credit_account].credit(pennies)
    else
      credit_account.credit(pennies)
    end
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
    @cash_accounts.values.map(&:pennies).sum
  end

  def total_cash_dollars
    '%0.02f' % (total_cash / 100.0).round(2)
  end

  def to_s
    %{
Coin Accounts
#{'=' * 45}
#{@coin_accounts.map { |k,v| "#{k.to_s.rjust(20)}: #{v.to_s.rjust(23)}\n" }.join}
#{'=' * 45}
#{"Total:".rjust(21)} #{"∀#{print_number(total_coins)}".rjust(23)}

AA Cash Accounts
#{'=' * 45}
#{@cash_accounts.map { |k,v| "#{k.to_s.rjust(20)}: #{v.to_s.rjust(23)}\n" }.join}
#{'=' * 45}
#{'Total:'.rjust(21) + "$#{print_number(total_cash_dollars)}".rjust(24)}

#{'Coin Price:'.rjust(21) + "$#{print_number(coin_value_dollars)}".rjust(24) + "/coin"}
    }
  end

  private

  def coin_value_dollars
    '%0.02f' % (coin_value / 100.0).round(2)
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
    "∀#{print_number(@coins)}"
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
    "$#{print_number(dollars)}"
  end
end

class REIAccount
  attr_reader :tokens

  def initialize(tokens)
    @tokens = tokens
  end

  def credit(tokens)
    @tokens += tokens
  end

  def debit(tokens)
    @tokens -= tokens
  end

  def to_s
    "REI #{print_number(@tokens)}"
  end
end
