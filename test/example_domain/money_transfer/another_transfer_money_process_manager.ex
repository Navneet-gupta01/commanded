defmodule Commanded.ExampleDomain.AnotherTransferMoneyProcessManager do
  @moduledoc false
  use Commanded.ProcessManagers.ProcessManager,
    name: "another_transfer_money_process_manager",
    router: Commanded.ExampleDomain.BankRouter

  defstruct transfer_uuid: nil,
            debit_account: nil,
            credit_account: nil,
            amount: nil,
            status: nil

  alias Commanded.ExampleDomain.AnotherTransferMoneyProcessManager
  alias Commanded.ExampleDomain.MoneyTransfer.Events.{MoneyTransferRequested}
  alias Commanded.ExampleDomain.BankAccount.Events.{MoneyDeposited, MoneyWithdrawn}
  alias Commanded.ExampleDomain.BankAccount.Commands.{DepositMoney, WithdrawMoney}

  def interested?(%MoneyTransferRequested{transfer_uuid: transfer_uuid}),
    do: {:start, transfer_uuid}

  def interested?(%MoneyWithdrawn{}), do: {:continue}
  def interested?(%MoneyDeposited{}), do: {:continue}

  def handle(%AnotherTransferMoneyProcessManager{}, %MoneyTransferRequested{
        transfer_uuid: transfer_uuid,
        debit_account: debit_account,
        amount: amount
      }) do
    %WithdrawMoney{account_number: debit_account, transfer_uuid: transfer_uuid, amount: amount}
  end

  def handle(
        %AnotherTransferMoneyProcessManager{
          transfer_uuid: transfer_uuid,
          credit_account: credit_account,
          debit_account: debit_account,
          amount: amount
        },
        %MoneyWithdrawn{account_number: account_number}
      )
      when account_number == debit_account do
    %DepositMoney{account_number: credit_account, transfer_uuid: transfer_uuid, amount: amount}
  end

  def handle(%AnotherTransferMoneyProcessManager{}, %MoneyDeposited{}), do: []

  ## state mutators

  def apply(%AnotherTransferMoneyProcessManager{} = transfer, %MoneyTransferRequested{
        transfer_uuid: transfer_uuid,
        debit_account: debit_account,
        credit_account: credit_account,
        amount: amount
      }) do
    %AnotherTransferMoneyProcessManager{
      transfer
      | transfer_uuid: transfer_uuid,
        debit_account: debit_account,
        credit_account: credit_account,
        amount: amount,
        status: :withdraw_money_from_debit_account
    }
  end

  def apply(%AnotherTransferMoneyProcessManager{} = transfer, %MoneyWithdrawn{}) do
    %AnotherTransferMoneyProcessManager{transfer | status: :deposit_money_in_credit_account}
  end

  def apply(%AnotherTransferMoneyProcessManager{} = transfer, %MoneyDeposited{}) do
    %AnotherTransferMoneyProcessManager{transfer | status: :transfer_complete}
  end
end
