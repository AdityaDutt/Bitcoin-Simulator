defmodule BTC_Node do
@moduledoc """
This module contains main wallet implementation. It creates nodes in network. They contact each other through genserver.
In this function, transaction takes place.
As soon as the transaction is sent from sender, signature is verified by receiver node. If signature is false, then transaction cancels.
But it does not affect program flow, this error is caught and the code runs after it as it is supposed to.
"""
  def start_link do
      {:ok,pid} = GenServer.start_link(__MODULE__,:ok, [])
      pid
  end


  def init(:ok) do
      {:ok, {"","","",0,[],[],"","",[],[]}} # private key, public key, public address, balance, transaction blockchain, public ledger(blockchain),
                                       # public_hash, transaction_output, my_block-chain, my_tranactions
  end

  def create_nodes(index) do
    pid = start_link()
    set_wallet(pid,index)
    #private_key = get_wallet_private_key(pid)
    #public_key = get_wallet_public_key(pid)
    balance = get_wallet_balance(pid)
    public_addr = get_wallet_public_addr(pid)
    public_hash = get_wallet_public_hash(pid)

    :global.register_name(index,pid)
    #IO.puts("I am #{index}. Activated!")
    #------------------------------------


  end

 def get_input(string,vin,start) do
    len = String.length(string)
    IO.puts string
    #string = String.slice(string,start..len - 1)
    #IO.puts string
    #IO.puts("index#{start + (1-1)*72} to index #{start + 71 + (1-1)*72} ")
    list = Enum.map(1..vin,fn x ->String.slice(string,start + (x-1)*72..start*(x) + 71 + (x-1)*72 )   end)
    last_index = start + 71 + (vin - 1)*72
    list = Enum.map(list,fn x-> [String.slice(x,0..63),String.slice(x,64..71)] end)

    indices = Enum.map(1..vin,fn x -> if rem(x,2) != 0 do
                                          Enum.at(list,x)
                                         end
     end)
      indices = Enum.filter(indices,fn x-> x != nil  end)
      prev_hash = list -- indices
    IO.inspect list
    IO.inspect indices
    IO.inspect prev_hash
    #IO.puts("num_input #{vin}last_index: #{last_index}")
    [prev_hash,indices,last_index]
 end

@doc """
In this function, receives the transaction. The Node firstly verfies signature and pubKeyScript conditions are verified.
After that transaction is confirmed.
"""
 def wait_for_output(pid,index,st_time,time) do
  # IO.puts("inside output")
   time = System.monotonic_time(:millisecond)
   if time - st_time > 7000 do
     IO.puts("transaction failed !")
     "-1"
   else
           h = GenServer.call(pid,{:get_h})
           #IO.inspect String.valid?(h)
           len = String.length(h)
           if len > 0 do
             ################
             #IO.puts("----received transaction")
             version = String.slice(h,0..7)
             vin = String.slice(h,8..15)
             vout = String.slice(h,16..23)
             vx  = Base.decode16!(vin,case: :mixed) |> :binary.decode_unsigned
             #IO.puts("num of inputs #{vx}")
             new_index = vx * 72 + 77
             #IO.puts("new index #{new_index}")
             lock_time = String.slice(h,24..77)
             #IO.puts("lock-time #{inspect lock_time}")
             #[mul_hash,mul_index,last_index] = get_input(h,vx,78)

             prev_out_hash = String.slice(h,78..141) # 78..85
             index = String.slice(h,142..149)
             amount = String.slice(h,len - 91..len - 84) #unaffected by vin
             scriptSig = String.slice(h,new_index+1..len - 92) #150
             #IO.puts("signatureScript #{inspect scriptSig}")
             scriptPubKey = String.slice(h,len - 83..len - 1) #unaffected by vin
        #     temp1 = version <> vin <> vout <> lock_time <> prev_out_hash <> index
        #     temp2 = amount <> scriptPubKey
        #     scriptSig = String.replace(h,temp1,"")
        #     scriptSig = String.replace(scriptSig,temp2,"")

             len1 = String.length(scriptSig)
        #     IO.puts("length of SigScript : #{len1}")
             sender_pub_key = String.slice(scriptSig,len1 - 130..len1 - 1)
             signature = String.slice(scriptSig,0..len1 - 131)
             #IO.puts("signature #{inspect signature}")
             sender_calc_pub_hash = String.slice(scriptPubKey,17..56)
        #     IO.puts h
             leng = String.length(h)
        #     IO.puts("lemgth of tx : #{leng}")

        """
             IO.inspect version
             IO.inspect vin
             IO.inspect vout
             IO.inspect lock_time
             IO.inspect prev_out_hash
             IO.inspect index
             IO.inspect scriptSig
             IO.inspect scriptPubKey
             IO.inspect amount
             IO.puts signature
             IO.puts sender_calc_pub_hash
             IO.puts sender_pub_key
        """
            pub_key = get_wallet_public_key(pid)

        #    IO.puts signature
        #    IO.puts sender_calc_pub_hash
        #    IO.puts sender_pub_key

            #signature = String.replace(signature, "0", "1")
            valid = TX_Valid.check_pubKeyScript_one_to_one(pub_key,scriptPubKey)
            if valid == 0 do
              IO.puts("----Could not verify PubkeyScript ! Transaction failed !")
              "-1"
            else

                valid = TX_Valid.check_signature_one_to_one(signature,sender_pub_key)
                if valid == 0 do
                IO.puts("----Sender signature invalid !  Transaction failed !")
                  "-1"
                end

            end
             ################
        #     wait_for_validation(pid,index)
           else
             wait_for_output(pid,index,st_time,time)
           end

   end

 end

@doc """
In this function, transaction is initiated. But first of all, it is checked that there is sufficient balance to carry out transaction.
"""
  def begin_one_to_one(pid,sender_index,rec_index,amount) do
    IO.puts("")
    IO.puts("I am #{sender_index} and i am sending #{amount} BTC to #{rec_index}")

    balance = get_wallet_balance(pid)
    valid = TX_Valid.tx_check_one_to_one(balance,amount)
    if valid == 0 do
      #Process.exit(pid,:kill)
      IO.puts "I--------Transaction invalid ! Insufficient balance-------"
      -1
    else
  #IO.puts("inside begin")
   Registry.unregister(Registry.Nonce, "records")
   rec_pid = :global.whereis_name(rec_index)
   # get public address of receiver
   rec_public_addr = get_wallet_public_addr(rec_pid)
   #[prefix, payload] = decode_public_hash(rec_public_addr)
   {prefix,payload} = Base58Check.decode58check(rec_public_addr)
   len = String.length(payload)
   d = String.slice(payload,0..len-2)
   d = prefix <> d
   rec_public_hash = d |> Base.encode16 #|> :binary.decode_unsigned

   sender_private_key = get_wallet_private_key(pid)
   {:ok,sender_private_key} = sender_private_key |> Base.decode16
   signature = :crypto.sign(:ecdsa,:sha256,"hello",[sender_private_key,:secp256k1]) |> Base.encode16()

   sender_public_key = get_wallet_public_key(pid) # |> :binary.decode_unsigned()

  # IO.puts("length of sign #{String.length(signature)} length of pub_key #{String.length(sender_public_key)} length of hash #{String.length(rec_public_hash)}")
   blockchain_size = Registry.count(Registry.Transaction)



   transaction = transaction(pid,blockchain_size,sender_public_key,signature,rec_public_hash,amount)
   if transaction == -1 do
     -1
   else
   Process.send(rec_pid, {:reply,transaction},[:noconnect]) #
   #GenServer.call(rec_pid,{:set_h,transaction})
   #IO.puts "----transaction_sent"


  # out = GenServer.call(pid,{:get_h})
   #IO.inspect out
   #--------------------------------------------------
   list = :global.registered_names()
   list = Enum.map(list,fn x -> :global.whereis_name(x) end)

   transaction
   end


   end
  end

"""
Transaction :
{
  version ,vin, vout,lock time,input :{
        { prev_hash
          index
        }
        scriptSig
      }
  output :{ value
          scriptPubKey
        }
}
"""

  def handle_info({:reply,msg}, state) do
    {_a,_b,_c,_d,_e,_f,_g,_h,_i,_j} = state
    state = {_a,_b,_c,_d,_e,_f,_g,msg,_i,_j}
    {:noreply, state}
  end

  # Coinbase TX
  def transaction(my_pid,ind,sender_public_key,signature,rec_public_hash,amount) when ind == 0 do

   len_pub_key = String.length(sender_public_key)
   len_pub_hash = String.length(rec_public_hash)
   len_sig = String.length(signature)
   #IO.puts("key #{len_pub_key} hash #{len_pub_hash} sig #{len_sig}")
   #signature = Integer.to_string(signature)
   date = DateTime.utc_now()
   date = DateTime.to_string(date) |> Base.encode16
   #IO.puts date
   version = 0 |> hex_num()
   vin = 1 |> hex_num()
   vout = 1 |> hex_num()
   lock_time = date
   prev_out_hash = String.duplicate("0",64) #{}"0" |> hash(:sha256) |> Base.encode16
   #IO.puts("----prevOut hash : #{inspect prev_out_hash}")
   index = 0|> hex_num()
   scriptSig = signature  <> sender_public_key
   scriptPubKey = "OP_DUP OP_HASH160" <> rec_public_hash <> "OP_EQUALVERIFY OP_CHECKSIG"

   amount = amount |> hex_num()
   input = prev_out_hash <> index  <> scriptSig
   output = amount  <> scriptPubKey
   transaction = (version <>   vin <>    vout <>    lock_time <>  input <> output )
   #IO.inspect transaction
   #IO.puts("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")

   #IO.puts("length #{String.length(transaction)}")
"""
   IO.inspect version
   IO.inspect vin
   IO.inspect vout
   IO.inspect lock_time
   IO.inspect prev_out_hash
   IO.inspect index
   IO.inspect scriptSig
   IO.inspect scriptPubKey
   IO.inspect amount
   IO.puts signature
   IO.puts rec_public_hash
   IO.puts sender_public_key
   IO.puts("input")
"""
#IO.puts signature
#IO.puts rec_public_hash
#IO.puts sender_public_key

   transaction

  end


  def transaction(my_pid,ind,sender_public_key,signature,rec_public_hash,amount) when ind > 0 do
    blockchain_size = Registry.count(Registry.Transaction)
    all_tx = Registry.lookup(Registry.Transaction,"records")
    {_,{prev_txid,prev_tx}} = Enum.at(all_tx,blockchain_size - 1)
    len_pub_key = String.length(sender_public_key)
    len_pub_hash = String.length(rec_public_hash)
    len_sig = String.length(signature)
    #IO.puts("key #{len_pub_key} hash #{len_pub_hash} sig #{len_sig}")
    #signature = Integer.to_string(signature)
    date = DateTime.utc_now()
    date = DateTime.to_string(date) |> Base.encode16
    #IO.puts date
    version = 0 |> hex_num()
    vin = 1 |> hex_num()
    vout = 1 |> hex_num()
    lock_time = date
    prev_out_hash = prev_txid # |> hash(:sha256) |> Base.encode16
    #prev_out_hash = 0 |> hex_num()
    #IO.puts("----prevOut hash : #{inspect prev_out_hash}")
    index = 0|> hex_num()
    [vin,new_list] = get_prev_tx(my_pid,amount,prev_out_hash <> index)


    #indices_x = find_indices_of_amount(final_amount_list,amount_list)
    #index = 0|> hex_num()
    scriptSig = signature  <> sender_public_key
    scriptPubKey = "OP_DUP OP_HASH160" <> rec_public_hash <> "OP_EQUALVERIFY OP_CHECKSIG"

    amount = amount |> hex_num()
    #input = prev_out_hash <> index  <> scriptSig
    input = new_list  <> scriptSig

    output = amount  <> scriptPubKey
    transaction = (version <>   vin <>    vout <>    lock_time <>  input <> output )
    #IO.inspect transaction
    #IO.puts("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")

    #IO.puts("length #{String.length(transaction)}")
 """
    IO.inspect version
    IO.inspect vin
    IO.inspect vout
    IO.inspect lock_time
    IO.inspect prev_out_hash
    IO.inspect index
    IO.inspect scriptSig
    IO.inspect scriptPubKey
    IO.inspect amount
    IO.puts signature
    IO.puts rec_public_hash
    IO.puts sender_public_key
    IO.puts("input")
 """

# IO.puts transaction
# leng = String.length(transaction)
 #IO.puts("lemgth of tx : #{leng}")
 #IO.puts rec_public_hash
 #IO.puts sender_public_key

    transaction

  end

 def get_prev_tx(my_pid,amount,zero_case_st) do
   index1 = get_my_transactions(my_pid)
   if Enum.count(index1) == 0 do
     vin = 1 |> hex_num()
     [vin,zero_case_st]
   else

     #IO.puts("----get_my_tx : #{inspect index1}")
     amount_list = Enum.map(index1,fn z -> Enum.at(z,0) end)
     #indices_list = Enum.map(index1,fn z-> Enum.at(z,1) end)

     final_amount_list = find_index([],amount_list,index1,amount)
     #IO.puts("----my_tx : #{inspect final_amount_list}")
     if final_amount_list == nil do
       vin = 1 |> hex_num()
       [vin,zero_case_st]

     else
     final_list_size = Enum.count(final_amount_list)
     #IO.puts("amount list size #{final_list_size}")
     vin = final_list_size |> hex_num()
     new_list = Enum.map(final_amount_list,fn z -> [Enum.at(z,2),Enum.at(z,1) |> hex_num()] end)
     new_list = List.flatten(new_list)
     #IO.puts("new_list: #{inspect new_list} ")
     new_list = Enum.reduce(new_list, fn x, acc ->  acc <> x end)
     #IO.puts("new_list: #{inspect new_list} ")
     [vin,new_list]
     end
   end
 end

  def find_index(init,index,index1,amount) do
     len = Enum.count(index)
     #IO.puts("length #{inspect init} amount #{amount}")
     x = Enum.filter(index,fn y -> y  >= amount end)
#     x = Enum.sort(x)
     if Enum.count(x) == 0 && len >= 2 do
        val = Enum.at(index,0)
        val1 = Enum.at(index1,0)
        init = init ++ [val1]
        amount = amount - val
        index = Enum.drop(index,1)
        index1 = Enum.drop(index1,1)
        find_index(init,index,index1,amount)
      else if len == 1 do
        #IO.puts("final #{inspect index}")
        val = 0 #Enum.find_index(index,fn z -> z == Enum.at(x,0) end)
        val1 = Enum.at(index1,val)
        #IO.puts("final #{inspect init ++ [val1]}")

        init ++ [val1]
      else

      end
     end

  end

@doc """
This function mines the bitcoins and find nonce whcih will give target number of zeros.
"""

  def mining(pid,index,target_zeros,header) do
    #IO.puts("I am miner process #{index} with pid #{inspect(pid)}" )
    z = work_on_range(0,0,header,target_zeros,index)

     #list =  Registry.lookup(Registry.Nonce, "records")
     #IO.puts("list #{inspect z}")
     z = List.flatten(z)
     z = Enum.uniq(z)
     z = Enum.filter(z,fn x-> Kernel.is_integer(x) == false  end)
     if Enum.count(z) > 0 do

       #[{_,{val}}] = Registry.lookup(Registry.Nonce, "records")
       val = Enum.at(z,0)
       val
     else
       -1
     end

  end

  def work_on_range(n,work,header,target_zeros,index) do
    #IO.puts("in b #{b} and e #{e}")
     work = check(n,header,target_zeros,index)
     if work == -1 do
       work_on_range(n+1,work,header,target_zeros,index)
     else
       #IO.inspect work
       [work]

     end
  end

  def check(n,header,target_zeros,index) do
    num = n
    n = n |> :binary.encode_unsigned |> Base.encode16 |> String.downcase
    len = String.length(n)
    zeros = 8 - len
    st = String.duplicate("0",zeros)
    n = st <> n
    test_header = (header <> n)
    header_bin = Base.decode16!(test_header, case: :lower) #header_hex.decode('hex')
    hash = header_bin |> hash(:sha256) |> hash(:sha256)
    final = hash |> Base.encode16 |> :binary.decode_unsigned(:little) |> :binary.encode_unsigned(:big)
    final_prefix = String.slice(final,0..target_zeros-1)
    match = String.duplicate("0", target_zeros)
    #count = Registry.count(Registry.Nonce)
    #if count > 0 do
      #IO.puts("shit from #{index}")
     # Process.exit(self(),:kill)
    #end

    if final_prefix == match do
      st1 = Integer.to_string(num)
      st2 = Integer.to_string(index)
      st = st1 <> " " <> st2
      st
      #IO.puts "found"
      # Registry.register(Registry.Nonce,"records",{st})
      #IO.puts num
      #Process.exit(self(),:kill)
      #IO.puts st
      #System.halt(1)
    else
      -1
    end

    end

@doc """
This functions validates the nonce after it is found by some lucky node.
"""
   def validator(_pid,index,nonce,target_zeros,header) do
     n = nonce
     n = n |> :binary.encode_unsigned |> Base.encode16 |> String.downcase
     len = String.length(n)
     zeros = 8 - len
     st = String.duplicate("0",zeros)
     n = st <> n
     test_header = (header <> n)
     header_bin = Base.decode16!(test_header, case: :lower) #header_hex.decode('hex')
     hash = header_bin |> hash(:sha256) |> hash(:sha256)
     final = hash |> Base.encode16 |> :binary.decode_unsigned(:little) |> :binary.encode_unsigned(:big)
     final_prefix = String.slice(final,0..target_zeros-1)
     match = String.duplicate("0", target_zeros)
     if match == final_prefix do
       [index,-2]
     else
       [index,-1]
     end

   end


  def hex_num(a) do
    z1 = a |> :binary.encode_unsigned |> Base.encode16
    len = String.length(z1)
    zeros = 8 - len
    st = String.duplicate("0",zeros)
    final = st <> z1
    final
  end

  def hex_string(a) do
    z1 = a |> Base.encode16
    len = String.length(z1)
    zeros = 8 - len
    st = String.duplicate("0",zeros)
    final = st <> z1
    final
  end

  def restore_h(pid) do
    GenServer.cast(pid,{:restore_h})
    #IO.inspect GenServer.call(pid,{:get_h})

  end

  def deductMoney(pid,amount) do
    GenServer.cast(pid,{:deduct,amount})
  end

  def handle_cast({:deduct,amount},state) do
    {_a,_b,_c,d,_e,_f,_g,_h,_i,_j} = state
    d = d - amount
    state = {_a,_b,_c,d,_e,_f,_g,_h,_i,_j}
    {:noreply,state}
  end

  def addMoney(pid,amount) do
    GenServer.cast(pid,{:add,amount})
  end

  def handle_cast({:add,amount},state) do
    {_a,_b,_c,d,_e,_f,_g,_h,_i,_j} = state
    d = d + amount
    state = {_a,_b,_c,d,_e,_f,_g,_h,_i,_j}
    {:noreply,state}
  end

  def collect_reward(pid,amount) do
    GenServer.cast(pid,{:collect,amount})
  end

  def handle_cast({:collect,amount},state) do
    {_a,_b,_c,d,_e,_f,_g,_h,_i,_j} = state
    d = d + amount
    state = {_a,_b,_c,d,_e,_f,_g,_h,_i,_j}
    {:noreply,state}

  end

  def handle_call({:get_h},_from,state)do
    {_a,_b,_c,_d,_e,_f,_g,h,_i,_j} = state
    {:reply,h,state}
  end

  def handle_cast({:restore_h},state)do
    {_a,_b,_c,_d,_e,_f,_g,h,_i,_j} = state
    h = ""
    state = {_a,_b,_c,_d,_e,_f,_g,h,_i,_j}
    {:noreply,state}
  end


  def handle_call({:start_transaction,msg},_from ,state) do
    {_a,_b,c,_d,_e,_f ,_g,_h,_i,_j } = state
    if msg == "sender" do
      {:reply, c ,state}
    end

  end

  def update_my_ledger(pid,block) do
    GenServer.cast(pid,{:set_ledger,block})
  end

  def get_my_ledger(pid) do
    GenServer.call(pid,{:get_ledger})
  end

  def handle_cast({:set_ledger,block} ,state) do
    {_a,_b,_c,_d,_e,_f ,_g,_h,i ,_j} = state
    i = i ++ [block]
    state = {_a,_b,_c,_d,_e,_f ,_g,_h,i ,_j}
    {:noreply ,state}
  end

  def handle_call({:get_ledger},_from ,state) do
    {_a,_b,_c,_d,_e,_f ,_g,_h,i,_j } = state
    {:reply,i ,state}

  end

  def update_my_transactions(pid,data,id,tx) do
     GenServer.cast(pid,{:set_my_tx,data,id,tx})
  end

  def get_my_transactions(pid) do
    GenServer.call(pid,{:get_my_tx})
  end

  def handle_cast({:set_my_tx,data,id,tx} ,state) do
    {_a,_b,_c,_d,_e,_f ,_g,_h,_i ,j} = state
    j = j ++ [[data,id,tx]]
    state = {_a,_b,_c,_d,_e,_f ,_g,_h,_i ,j}
    {:noreply ,state}
  end

  def handle_call({:get_my_tx},_from ,state) do
    {_a,_b,_c,_d,_e,_f ,_g,_h,_i,j } = state
    {:reply,j ,state}

  end

  def random_alphanumeric() do
    alpha =  Enum.to_list(65..90)
    list = Enum.map(1..10,fn _x -> Enum.at(alpha,Enum.random(0..25)) end)
    key = List.to_string(list)
    key
  end

  def hash(val,algo) do
   :crypto.hash(algo, val)

  end

  def set_wallet(pid, index) do

    GenServer.cast(pid, {:set_wallet,index})
  end

  def get_wallet_private_key(pid) do
    GenServer.call(pid, {:get_private_key})
  end

  def get_wallet_public_key(pid) do
    GenServer.call(pid, {:get_public_key})
  end

  def get_wallet_public_hash(pid) do
    GenServer.call(pid, {:get_public_hash})
  end

  def get_wallet_balance(pid) do
    GenServer.call(pid, {:get_balance})
  end

  def get_wallet_public_addr(pid) do
    GenServer.call(pid,{:get_public_addr})
  end

  def calculate_public_hash(pub_key) do
        public_hash = pub_key
                      |> hash(:sha256)
                      |> hash(:ripemd160)
        public_hash
  end

  def handle_cast({:set_wallet,index} ,state) do
    {_a,_b,_c,_d,e,f ,_g,_h,_i ,_j} = state

    {public_key, private_key} = :crypto.generate_key(:ecdh, :secp256k1)
    #IO.inspect public_key
    #IO.inspect private_key

    public_hash = public_key
                  |> hash(:sha256)
                  |> hash(:ripemd160)
    #version = <<0x00>>
    public_addr = public_hash
                  |> Base58Check.encode58check(0)

    [public_addr,public_hash,public_key,private_key] = resolve_checksum_error(public_addr,public_hash,public_key,private_key)
    #d = Enum.random(10000..10000)
    d = balance(index)
    public_key = public_key |> Base.encode16
    private_key = private_key |> Base.encode16



    state={private_key,public_key,public_addr,d,e,f,Integer.to_string(:binary.decode_unsigned(public_hash),16),"",_i,_j}
    {:noreply, state}
  end

  def balance(index) do
    if index == 1 do
      1000
    else
      0
    end
  end

@doc """
This function resolves "checksum doesn't match !" error.In thus case, we genearet another pair of private and public key
"""
  def resolve_checksum_error(addr,hash,public_key,private_key) do
    {prefix,payload} = Base58Check.decode58check(addr)
    if prefix == -1 || payload == -1 do
      {public_key, private_key} = :crypto.generate_key(:ecdh, :secp256k1)
      hash = public_key
                    |> hash(:sha256)
                    |> hash(:ripemd160)
      addr = hash |> Base58Check.encode58check(0)
      resolve_checksum_error(addr,hash,public_key,private_key)
    else
      [addr,hash,public_key,private_key]
    end

  end

  def handle_call({:get_private_key},_from ,state) do
    {a,_b,_c,_d,_e,_f ,_g,_h,_i,_j } = state
    {:reply, a,state}
  end

  def handle_call({:get_public_key},_from ,state) do
    {_a,b,_c,_d,_e,_f ,_g,_h,_i,_j } = state
    {:reply, b,state}
  end

  def handle_call({:get_public_hash},_from ,state) do
    {_a,_b,_c,_d,_e,_f,g,_h,_i ,_j} = state
    {:reply, g,state}
  end

  def handle_call({:get_balance},_from ,state) do
    {_a,_b,_c,d,_e,_f ,_g,_h,_i ,_j} = state
    {:reply, d,state}
  end

  def handle_call({:get_public_addr},_from ,state) do
    {_a,_b,c,_d,_e,_f ,_g,_h,_i,_j } = state
    {:reply, c,state}
  end


end
