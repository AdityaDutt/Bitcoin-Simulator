defmodule TX_Valid do
@moduledoc """
This module validates a transaction. It has 3 main functions -
1. To check signature of sender
2. Whether receiver can satisfy conditions of ScriptPubKey or not
3. Check if sent money > received money. If sent money is less than required money, an error is thrown.
"""
  def tx_check_one_to_one(pay,rec) do
    if pay >= rec do
      IO.puts("----TX balance valid")
      1
    else
      #IO.puts("----TX balance invalid ! Insufficient balance.")
      0
    end

  end

  def check_signature_one_to_one(sign,pub_key) do
  {:ok,signature} = sign |> Base.decode16
  {:ok,public_key} = pub_key |> Base.decode16


  valid = :crypto.verify(

      :ecdsa,
      :sha256,
      "hello",
      signature,
      [public_key, :secp256k1]
    )

    if valid == true do
      IO.puts("----sender signature valid !")
      1
    else
      #IO.puts("----sender signature invalid !")
      0
    end

  end

  def check_pubKeyScript_one_to_one(pub_key,scriptPubKey) do
  {:ok,public_key} =  pub_key |> Base.decode16

   public_hash = public_key
                 |> hash(:sha256)
                 |> hash(:ripemd160) |> Base.encode16
   len = String.length(scriptPubKey)
   rec_hash = String.slice(scriptPubKey,17..len - 27)
   #IO.puts rec_hash
   #IO.puts public_hash

    if public_hash == rec_hash do
      IO.puts("----PubkeyScript verified !")
      1
    else
      #IO.puts("----Could not verify PubkeyScript !")
      0
    end

  end

  def hash(val,algo) do
   :crypto.hash(algo, val)

  end

end
