defmodule Project4 do
  use Application
@moduledoc """
This is the main module which takes arguments n and k from user, parses it and then converts them
to integer. Then, it calls Parent Module and passes the arguments n and k in that module.
"""
  def start(_type,_args) do

    n = Enum.at(System.argv(),0)
    num_transactions = String.to_integer(n,10)

    Bitcoin.main(num_transactions)

  end
end
