defmodule Bitcoin.Base58CheckTest do
  use ExUnit.Case
  alias Bitcoin.Base58Check

  test "nonce gives target zeros in header" do
    header = "01000000daf21abf3fa461835c7ea0ec875a58feb57c0e0c490bd72bc06a5ebcfc1c70fb842df2b704257d9bfa9d872baf45e0b162f97963b163f58792424297b89fc255323031382d31312d32362032333a32363a31372e3538303030305a000fffff"
    nonce = 731
    difficulty = 2
    index = Enum.random(1..100)
    pid = "#PID<0.125.0>"

    if assert BTC_Node.validator(pid,index,nonce,difficulty,header) == [index,-2] do
      IO.puts "----Nonce is correct. Gives corect number of zeros swhen hashed with header."

    end

  end

end
