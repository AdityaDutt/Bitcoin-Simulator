# Bitcoin

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `bitcoin` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bitcoin, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/bitcoin](https://hexdocs.pm/bitcoin).

Distributed Operating Systems Project
-------------------------------------
Project4.1 Bitcoin Simulator
-------------------------------------

Group Members -
  Aditya Dutt 14530933
  Richa Dutt  83877619
-------------------------------------
How to run-
1. Go inside directory Project4.1.
2. There are two folders - Project and Project_bonus.
(Now, following steps are same for both Project and Project_bonus)
3. Go inside Project. Go inside directory - bitcoin.
4. Now, to compile code type : mix compile
5. To run, type : mix run Project4 num_of_transactions
-------------------------------------

Important comments regarding project-

 1. Bitcoin simulator is working for 60 nodes. ( We tried it for maximum 80 nodes)
 
 2. Target with most zeros that we have tried is with - 6 zeros.

*3. We have implemented all the validity checks and tests in the main code itself. 
    
    a) Some of the tests related to transaction like - "signature validity", "ScriptPubKey" and 
      "Sufficient Balance check" are implemented in Transaction_validity_check.ex file.
      If at any point, any of the conditions are failed to be satisfied, the transactions cancels
      as it should be. In that case, the transaction is not added to block and after catching that
      error, rest of the transactions starts.

    b) When a transaction is successful, it is added to transaction chain but it's previous_transaction_id
      field is compared to all previous transactions which this transaction is referring to. In case that
      transaction_id is invalid, that transaction is immediately deleted from chain and it's block is not
      created.  

    c) Similarly, when a block is added, it's previous_block_hash is matched with hash of previous block. If
      that fails, we delete that block.

    d) We have tested if Base58Check gives correct value in code.In case, the checksum does not match we
    generate another pair of public and private key to make sure that checksum matches. 
    
    e) Rest of the minor tests about hash and ripmend160 are implemented in ExUnit Test.
    So, we have applied all these checks(tests) in the main file, if nay of these test fails then transaction
    does not happen( Comments are added in the code). But still, we have added 12 test cases in ExUnit tests 
    to check for correctness.

 4. We have implemented ExUnit cases in test folder. All the tests are in same file 
    i.e., "bitcoin_test.exs".
 
 5. Our code prints all the data on screen. We have printed steps that at which point what is going on.
    If all the conditions of transactions are met, they are printed on screen. In the end, transaction chain and
    block chain is printed.
