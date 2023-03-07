require_relative 'util'

class Vault
  def initialize(coins, cash)
    @coin_vault = CoinVault.new(coins)
    @cash_vault = CashVault.new(cash)
  end

  def coins
    @coin_vault.coins
  end

  def cash
    @cash_vault.pennies
  end

  def credit_coins(coins)
    @coin_vault.credit(coins)
  end

  def credit_cash(pennies)
    @cash_vault.credit(pennies)
  end

  def debit_coins(coins)
    @coin_vault.debit(coins)
  end

  def debit_cash(pennies)
    @cash_vault.debit(pennies)
  end

  def coin_value
    @cash_vault.pennies / @coin_vault.coins
  end

  def to_s
    "#{@coin_vault}, #{@cash_vault} = $#{print_number(coin_value_dollars)}"
  end

  private

  def coin_value_dollars
    '%0.02f' % (coin_value / 100.0).round(2)
  end
end

class CoinVault
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
    "AA#{print_number(@coins)}"
  end
end

class CashVault
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
