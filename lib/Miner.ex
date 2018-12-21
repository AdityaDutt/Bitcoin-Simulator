defmodule Miner do
 @block_reward 50
@moduledoc """
This Module implements Miner nodes. All the miner node are waiting for transaction to happen. As soon as a transaction takes place
they start finding nonce that when hashed with header gives target number of zeros.
After a lucky node finds nonce, all other nodes validate it if it is correct or not. If it is correct, then the block is added to blockchain
and the miner is rewarded with 50 BTC.
(This modue contains merkle root function and listing all the previous transactions in case of multiple inputs).
"""
 def get_input(string,vin,start) do
    len = String.length(string)
    #IO.puts string
    #string = String.slice(string,start..len - 1)
    #IO.puts string
    #IO.puts("index#{start + (1-1)*72} to index #{start + 71 + (1-1)*72} ")
    list = Enum.map(1..vin,fn x ->String.slice(string,start + (x-1)*72..start*(x) + 71 + (x-1)*72 )   end)
    last_index = start + 71 + (vin - 1)*72
    list = Enum.map(list,fn x-> [String.slice(x,0..63),String.slice(x,64..71)] end)
    list = List.flatten(list)

    prev_hash = Enum.filter(list,fn x-> String.length(x) > 8    end)
      #prev_hash = Enum.filter(prev_hash,fn x-> x != nil  end)
      indices = list -- prev_hash
    #IO.puts("indices : #{inspect indices}")
    #IO.puts("prev_hash : #{inspect prev_hash}")
    [prev_hash,indices,last_index]
 end

 def start_mining_boys(sender_index,rec_index,nodes,transaction) do

   vin = String.slice(transaction,8..15)
   vout = String.slice(transaction,16..23)
   #IO.puts("vin #{vin} vout #{vout}")
   date = DateTime.utc_now()
   date = DateTime.to_string(date) |> Base.encode16
   vin  = Base.decode16!(vin,case: :mixed) |> :binary.decode_unsigned
   vout  = Base.decode16!(vout,case: :mixed) |> :binary.decode_unsigned

   len = String.length(transaction)
   new_index = vin * 72 + 77
   [mul_hash,mul_index,last_index] = get_input(transaction,vin,78)
   amount = String.slice(transaction,len - 91..len - 84) #unaffected by vin
   scriptSig = String.slice(transaction,new_index+1..len - 92) #150
   scriptPubKey = String.slice(transaction,len - 83..len - 1) #unaffected by vin
   tx_output = amount <> scriptPubKey
   merged_tx = Enum.map(0..vin-1, fn x -> [Enum.at(mul_hash,x) <> Enum.at(mul_index,x) <> scriptSig <> tx_output ] end)
   merged_tx = List.flatten(merged_tx)

   #-------block creation---------

   transaction_counter = get_num_transactions(vin,vout)

   tx_hash = get_list_transactions(merged_tx,vin,vout)
   version = "01000000"
   blocks = Registry.lookup(Registry.Block,"records" )
   block_count = Enum.count(blocks)
   prev_block_hash = get_hash_prev_block(block_count,blocks)
   merkle_root = get_merkle_root(merged_tx,vin,vout)
   #IO.puts("prev_block-hash #{inspect prev_block_hash}")
   #IO.puts("merkle root #{inspect merkle_root}")
   time = date
   target = "000fffff"
   block_header = (version <> prev_block_hash <> merkle_root <> time <> target )
   block = block_header <> transaction_counter <> tx_hash
   nonce = :ets.new(:nonce, [:duplicate_bag,:public])

   miners = nodes -- [sender_index]

   header_hex = ("01000000" <>
                  "81cd02ab7e569e8bcd9317e2fe99f2de44d49ab2b8851ba4a308000000000000" <>
                  "e320b6c2fffc8d750423db8b1eb942ae710e951ed797f7affc8892b0f1fc122b" <>
                  "c7f5d74d" <>
                  "f2b9441a")
   #header_hex = transaction

   header_hex = block_header |> String.downcase
   #IO.puts header_hex

   time_beg = System.monotonic_time(:millisecond)
   target = Enum.random(1000..3000) #5
   target = div(target,1000)
   target = round target
   #IO.puts ("----difficulty #{target}")
   pz = Enum.map(miners,fn x ->  spawn fn-> y = BTC_Node.mining(:global.whereis_name(x),x,target,header_hex)
         # IO.inspect y
                       :ets.insert(nonce, {"value",y})

       end
    end)
    f = 0
    Enum.each(pz,fn x ->   ref = Process.monitor(x)
      receive do
      {:DOWN, ^ref, _, _, _} -> f = f + 1 #IO.puts "Process #{inspect(x)} is down"

      end
    end)
   #IO.puts("mining finished")
   list = :ets.match(nonce, {"value", :"$2"})
   :ets.delete(nonce)
   list = List.flatten(list)
   list = Enum.uniq(list)
   #IO.inspect list
   list = Enum.filter(list,fn x-> Kernel.is_number(x) == false end)
   [nonce,lucky_index] = get_nonce_index(list)
   #IO.puts("----Nonce is #{nonce} and node: #{lucky_index} found it")
   # give reward to lucky node
   BTC_Node.collect_reward(:global.whereis_name(lucky_index),@block_reward)
   # broadcast nonce to all nodes
   validator_rec = :ets.new(:validator_rec, [:duplicate_bag,:public])
   validator_nodes = miners -- [lucky_index]
   pz = Enum.map(validator_nodes,fn x ->  spawn fn-> y = BTC_Node.validator(:global.whereis_name(x),x,nonce,target,header_hex)
         # IO.inspect y
                       :ets.insert(validator_rec, {"value",y})

       end
    end)
    f = 0
    Enum.each(pz,fn x ->   ref = Process.monitor(x)
      receive do
      {:DOWN, ^ref, _, _, _} -> f = f + 1 #IO.puts "Process #{inspect(x)} is down"

      end
    end)

    list = :ets.match(validator_rec, {"value", :"$2"})
    :ets.delete(validator_rec)
    result = List.flatten(list)
    agree = Enum.count(result,fn x-> x == -2  end)
    disagree = Enum.count(result,fn x-> x == -1  end)
    #IO.puts("----#{agree} / #{Enum.count(nodes) - 3} accepted tX and ----#{disagree} / #{Enum.count(nodes) - 3} did not accept tX")

  #-------Generate Block4
  #IO.inspect nonce
  st_nonce = nonce |> :binary.encode_unsigned |> Base.encode16
  len = String.length(st_nonce)
  zeros = 8 - len
  st = String.duplicate("0",zeros)

  final = st <> st_nonce
  block_header = header_hex <> final

  block = block_header <> transaction_counter <> tx_hash
  block_size = byte_size(block)  |> :binary.encode_unsigned |> Base.encode16
  block = block_size <> " " <>  block_header <> " " <> transaction_counter <> " " <> tx_hash

  #IO.inspect block
  IO.puts("")
  IO.puts("")
  IO.puts("BLOCK GENERATED :")
  IO.puts(" _______________________________________________________________________________________________")
  IO.puts("|  block-size : #{inspect block_size}")
  IO.puts("|  version : #{inspect version}")
  IO.puts("|  merkle root : #{inspect merkle_root} ")
  IO.puts("|  tx : [ #{inspect tx_hash} ]")
  IO.puts("|  time : #{inspect time}")
  IO.puts("|  difficulty : #{target}")
  IO.puts("|  nonce : #{nonce}")
  IO.puts("|  previous block hash : #{inspect prev_block_hash}")
  IO.puts(" _______________________________________________________________________________________________")


  block



 end

 def get_nonce_index(list) do
   if Enum.count(list) > 0 do
     val = String.split(Enum.at(list,0))
     nonce = Enum.at(val,0) |> String.to_integer
     index = Enum.at(val,1) |> String.to_integer
     [nonce,index]
   else
     [-1,-1]
   end
 end

def get_num_transactions(vin,vout) do
  "#{vout}"
end

def get_list_transactions(transaction,vin,vout) do
  tx = Enum.reduce(transaction, fn x, acc ->  acc <> x end)
  tx_hash = tx |> hash(:sha256) |> Base.encode16
  tx_hash

end

@doc """
This function makes transactions in even number so that there merkle root can be taken.
"""
def make_even(tx) do
  #IO.inspect tx
  len = Enum.count(tx)
  #IO.puts("make_evn len #{len}")

  #IO.puts Enum.at(tx,len - 1)
  if rem(len,2) == 0 do
    tx
  else
    st = Enum.at(tx,len - 1)
    tx ++ [st]
  end

end

@doc """
This function finds hash of previous block.
"""
def get_hash_prev_block(block_count,blocks) do

  if block_count == 0 do
    "0000000000000000000000000000000000000000000000000000000000000000"
  else
    blocks = Registry.lookup(Registry.Block,"records" )
    len_block = Enum.count(blocks)
    {_,{prev_block}} = Enum.at(blocks,len_block - 1)
    hash = prev_block |> hash(:sha256) |> Base.encode16
    hash
#    "0000000000000000000000000000000000000000000000000000000000000000"

  end
end

def hash(val,algo) do
 :crypto.hash(algo, val)

end

@doc """
This function finds the merkle root of transactions
"""
def get_merkle_root(transaction,vin,vout) do
  transaction = make_even(transaction)
  #IO.inspect transaction
  tx = take_merkle(transaction)
  if Enum.count(tx) > 1 do
    get_merkle_root(tx,vin,vout)
  else
    #IO.puts("final #{inspect tx}")
    Enum.at(tx,0)
  end

end

def take_merkle(transaction) do
  len = Enum.count(transaction)
  array = Enum.map(0..len - 1,fn x -> x end)
  array = Enum.filter(array,fn x -> rem(x,2) == 0 end)
  tx = Enum.map(array,fn x -> Enum.at(transaction,x) <> Enum.at(transaction,x + 1) |> hash(:sha256) |> Base.encode16  end)
  tx
end

end
