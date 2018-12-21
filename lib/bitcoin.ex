defmodule Bitcoin do
@moduledoc """

This module takes number of transactions as input. First of all, only one node in netwokr has Bitcoins, then it makes a transaction
(Genesis transaction). After that every node makes transaction with other node, if it has enough balance.
As soon as a node tries to make a transaction, first of it's balance is checked. If it is insufficient, then the transaction cancels.
After that, Module BTC_NOde is called to make transaction if there is sufficient balance.
This module stores transactions and blocks. And checks if they are valid.
For example - A transaction has previous transaction ID field, so it is checked if previous_transaction_id exists or not?

---> I HAVE IMPLEMENTED THESE TEST CASES IN MAIN CODE ITSELF APART FROM EXUNIT TEST CASES. <---
---> IN THE CODE, SIGNATURE AND PUBKEYSCRIPT ARE ALSO CHECKED BEFORE MAKING TRANSACTION. <---


"""
  def main(num) do
    if num > 1 do
    # num-> number of participants
    #Registry.start_link(keys: :duplicate, name: Registry.Public_Ledger)
    Registry.start_link(keys: :duplicate, name: Registry.Nonce)   # to find nonce_value
    Registry.start_link(keys: :duplicate, name: Registry.Nonce_broadcast)  # to broadcast nonce_value so other nodes can know
    Registry.start_link(keys: :duplicate, name: Registry.TX_broadcast)  # to broadcast nonce_value so other nodes can know
    Registry.start_link(keys: :duplicate, name: Registry.Block)  # to broadcast nonce_value so other nodes can know
    Registry.start_link(keys: :duplicate, name: Registry.Transaction)  # to broadcast nonce_value so other nodes can know
    Registry.start_link(keys: :duplicate, name: Registry.Hold)  # to broadcast nonce_value so other nodes can know




    #--------create public address--------------------
    Enum.each(1..num,fn x -> BTC_Node.create_nodes(x)end)

    list = :global.registered_names()
    size = Enum.count(list)
    list1 = Enum.uniq(list)
    size1 = Enum.count(list1)
    #IO.puts("size : #{size} uniq_size : #{size1}")
    pid = Enum.map(list1,fn x-> :global.whereis_name(x) end)
    #IO.inspect pid
    IO.puts("---------x-----x------x------x------x-----x----")
    #IO.inspect Registry.lookup(Registry.Public_Ledger,"records")
    #--------------------------------------------------
    balances = Enum.map(list1,fn x-> BTC_Node.get_wallet_balance(:global.whereis_name(x) )end)
    total = Enum.sum(balances)
    list1 = Enum.sort(list1)

    a = 1
    b = Enum.random(2..num)
    pid = :global.whereis_name(a)
    balance = BTC_Node.get_wallet_balance(pid)
    amount_pay = div(balance,100)
    transaction_one_to_one(a,b,num,amount_pay,0)
    balances = Enum.map(list1,fn x-> BTC_Node.get_wallet_balance(:global.whereis_name(x) )end)
    total = Enum.sum(balances)

    Enum.each(1..num-1,fn x-> [a,b] = get_balance_nodes(list1)

    pid = :global.whereis_name(a)
    balance = BTC_Node.get_wallet_balance(pid)
    amount_pay = Enum.random(1..balance)
    transaction_one_to_one(a,b,num,amount_pay,0)
    balances = Enum.map(list1,fn x-> BTC_Node.get_wallet_balance(:global.whereis_name(x) )end)
    IO.inspect balances
    total = Enum.sum(balances)
    list = Registry.lookup(Registry.Transaction, "records")

    check_transaction_correctness(list)  # check correctness of transaction

    list = Registry.lookup(Registry.Block, "records")

    check_block_correctness(list) # check correctness of block

  end)

    IO.puts("")
    IO.puts("Transactions : [transaction_id,transaction]")
    IO.puts("-------------------------------------------------------------------------------------------")
    tx = Registry.lookup(Registry.Transaction, "records")
    tx = Enum.map(tx,fn x -> {_,{txid,tx}} = x
                        IO.puts("txid : #{inspect txid} ")
                        IO.puts("transaction : #{inspect tx}")
                        IO.puts("")
                        [txid,tx]
                        end)
    #IO.inspect tx
    IO.puts("")
    IO.puts("Blocks :")
    IO.puts("-------------------------------------------------------------------------------------------")
    blk = Registry.lookup(Registry.Block, "records")
    blk = Enum.map(blk,fn x -> {_,{block}} = x
                        IO.puts("Block : #{inspect block}")
                        IO.puts("   ")
                        [block]
                        end)
                        IO.puts("Total tx : #{Enum.count(tx)}")
                        IO.puts("Total blocks : #{Enum.count(blk)}")

    #IO.inspect blk
    list = Registry.lookup(Registry.Block, "records")
    list = Enum.map(list,fn x-> {_,{val}} = x
                                   val |> hash(:sha256) |> Base.encode16
                                 end)
    #IO.inspect list


    IO.puts("---x----Finished----x----")
    #:ok
    System.halt(1)
   else
    IO.puts("Error ! Only one node in network")
    #:error
    System.halt(1)

  end

  end

@doc """
This function gets the node with sufficient balance in order to make transaction
"""

  def get_balance_nodes(list) do
    nodes = Enum.map(list,fn x-> if BTC_Node.get_wallet_balance(:global.whereis_name(x) ) > 0 do
                                  x
                                else
                                  -1
                                end
                                end)
    #IO.inspect nodes
    nodes = Enum.filter(nodes,fn x -> x > 0  end)
    a = Enum.random(nodes)
    nodes = nodes -- [a]
    #IO.inspect nodes
    b = Enum.random(nodes)
  #  IO.puts("node a : #{ inspect BTC_Node.get_wallet_balance(:global.whereis_name(a))} node b : #{inspect BTC_Node.get_wallet_balance(:global.whereis_name(b))}")
    [a,b]
  end

  def check_transaction_correctness(list) do
#78

    size = Enum.count(list)
    #IO.puts("size #{size}")
    {_,{_,current}} = Enum.at(list,size - 1)
    prev = list -- [ current]
    #size = Enum.count(prev)
    #IO.puts("size #{size}")
    prev = Enum.map(prev,fn x -> {_,{val,_}} = x
                             val   end)
    current = String.slice(current,78..141)
    exist = Enum.find_value(prev, fn x-> x == current end)
    if exist == true do
      1
    #  IO.puts("correct_tx")
    else
    #  IO.puts("incorrect_tx")
      0
    end
  end

  def check_block_correctness(list) do

    size = Enum.count(list)
    ind = size - 2
    {_,{val}} = Enum.at(list,ind )
    correct_val = val |> hash(:sha256) |> Base.encode16 |> String.downcase
    {_,{b}} = Enum.at(list,ind + 1)
    prev_block_hash = String.slice(b,13..76)
    #IO.puts("got hash : #{inspect prev_block_hash}")
    #IO.puts("correct : #{inspect correct_val}")
    if prev_block_hash == correct_val do
      1
    #  IO.puts "correct_bl"
    else
      0
    #  IO.puts "incorrect_bl"
    end


  end

  def get_two_random_num(range) do
    num1 = Enum.random(1..range)
    y = Enum.filter(1..range, fn x-> x != num1  end)
    num2 = Enum.random(y)
    [num1,num2]
  end

  def transaction_one_to_one(ind1,ind2,num,amount,global_count) do
    temp_trans = :ets.new(:temp_trans, [:duplicate_bag,:public])
    st_time = System.monotonic_time(:millisecond)
    pz = Enum.map(1..2,fn x-> if x == 1 do

    spawn(fn ->  tr = BTC_Node.begin_one_to_one(:global.whereis_name(ind1),ind1,ind2,amount)
                if tr != -1 do
                  :ets.insert(temp_trans, {"transaction",tr})
                end

                             end)
  else
    spawn(fn ->   tr =  BTC_Node.wait_for_output(:global.whereis_name(ind2),ind2,st_time,st_time)
    :ets.insert(temp_trans, {"transaction",tr})

  end)

  end
  end)

    f = 0
    Enum.each(pz,fn x ->   ref = Process.monitor(x)
      receive do
      {:DOWN, ^ref, _, _, _} ->  f = f + 1 #IO.puts "Process #{inspect(x)} is down"

      end
    end)


   transaction = :ets.match(temp_trans, {"transaction", :"$2"})
   transaction1 = List.flatten(transaction)
   ch_len = Enum.count(transaction1)
   map = Enum.filter(1..ch_len,fn x->  Enum.at(transaction1,x - 1 ) ==  "-1"    end)
   check_script = Enum.count(map)
   #IO.puts("check #{check_script}")
   :ets.delete(temp_trans)
   if Enum.count(transaction) > 0 && check_script == 0 do
     transaction = List.flatten(transaction)
     transaction = Enum.at(transaction,global_count)
     Registry.register(Registry.TX_broadcast,"transaction",{transaction})
     #IO.puts("----transaction broadcasted")
     list = Registry.lookup(Registry.TX_broadcast,"transaction")
     {_,{transaction}} = Enum.at(list,global_count )
     txid = transaction |> hash(:sha256) |> Base.encode16
     Registry.register(Registry.Transaction, "records", {txid,transaction})
     #IO.inspect transaction
      node_list = :global.registered_names()
      pid_list = Enum.map(node_list,fn x -> :global.whereis_name(x) end)
      out_block = Miner.start_mining_boys(ind1,ind2,node_list,transaction)
      Registry.register(Registry.Block,"records",{out_block})


      BTC_Node.restore_h(:global.whereis_name(ind1))
      BTC_Node.restore_h(:global.whereis_name(ind2))
      Registry.unregister(Registry.TX_broadcast, "transaction")
      # money transfer when blocks are confirmed
      BTC_Node.deductMoney(:global.whereis_name(ind1),amount)
      BTC_Node.addMoney(:global.whereis_name(ind2),amount)
      len = String.length(transaction)
      amount = String.slice(transaction,len - 91..len - 84)
      amount = Base.decode16!(amount,case: :mixed) |> :binary.decode_unsigned

      #IO.puts("amount #{amount}")
      temp_list = Registry.lookup(Registry.TX_broadcast,"transaction")
      id = check_length(temp_list)
      BTC_Node.update_my_transactions(:global.whereis_name(ind2),amount,id,transaction|> hash(:sha256) |> Base.encode16)
      #BTC_Node.update_my_transactions(:global.whereis_name(ind2),amount,id+1,transaction|> hash(:sha256) |> Base.encode16)

      list = :global.registered_names()
      list = Enum.sort(list)
      # every node add block to their block-chain
      Enum.each(list,fn x-> BTC_Node.update_my_ledger(:global.whereis_name(x ), out_block) end)


    else
      Registry.unregister(Registry.TX_broadcast, "transaction")
      BTC_Node.restore_h(:global.whereis_name(ind1))
      BTC_Node.restore_h(:global.whereis_name(ind2))

    end


  end

  def hash(val,algo) do
   :crypto.hash(algo, val)

  end

  def check_length(list) do
    if Enum.count(list) > 0 do
      Enum.count(list) - 1
    else
      0
    end
  end


end
