defmodule Base58Check do
@moduledoc """
This module does Base58 encoding with checksum and decoding. This is used in creating public address of node.
"""
  bc58_alphabet = Enum.with_index('123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz')

  for {encoding, value} <- bc58_alphabet do
    defp do_encode58(unquote(value)), do: unquote(encoding)
    defp do_decode58(unquote(encoding)), do: unquote(value)
  end

  def encode58(data_val) do
    encoded_zeroes = convert_leading_zeroes(data_val, [])
    integer = if is_binary(data_val), do: :binary.decode_unsigned(data_val), else: data_val
    encode58(integer, [], encoded_zeroes)
  end
  defp encode58(0, acc, encoded_zeroes), do: to_string([encoded_zeroes|acc])

  defp encode58(integer, acc, encoded_zeroes) do
    encode58(div(integer, 58), [do_encode58(rem(integer, 58)) | acc], encoded_zeroes)
  end

  defp convert_leading_zeroes(<<0>> <> data_val, encoded_zeroes) do
    encoded_zeroes = ['1'|encoded_zeroes]
    convert_leading_zeroes(data_val, encoded_zeroes)
  end

  defp convert_leading_zeroes(_data_val, encoded_zeroes), do: encoded_zeroes

  def decode58(code) when is_binary(code) do
    decode58(to_charlist(code), 0)
  end

  def decode58(code), do: raise(ArgumentError, "expects base58-encoded binary")

  defp decode58([], acc), do: acc

  defp decode58([c|code], acc) do
    decode58(code, (acc * 58) + do_decode58(c))
  end

  def encode58check(prefix, data_val) when is_binary(prefix) and is_binary(data_val) do
    data_val = case Base.decode16(String.upcase(data_val)) do
        {:ok, bin}  ->  bin
        :error      ->  data_val
      end
    versioned_data_val = prefix <> data_val
    checksum = calculate_checksum(versioned_data_val)
    encode58(versioned_data_val <> checksum)
  end
  def encode58check(prefix, data_val) do
    prefix = if is_integer(prefix), do: :binary.encode_unsigned(prefix), else: prefix
    #IO.inspect prefix
    data_val = if is_integer(data_val), do: :binary.encode_unsigned(data_val), else: data_val
    encode58check(prefix, data_val)
  end

  def decode58check(code) do
    decoded_bin = decode58(code) |> :binary.encode_unsigned()
    payload_size = byte_size(decoded_bin) - 5

    <<prefix::binary-size(1), payload::binary-size(payload_size), checksum::binary-size(4)>> = decoded_bin
    if calculate_checksum(prefix <> payload) == checksum do
      {prefix, payload}
    else
      #IO.puts("checksum doesn't match")
      {-1,-1}
    end
  end

  def hash(val,algo) do
   :crypto.hash(algo, val)

  end

  defp calculate_checksum(versioned_data_val) do
    <<checksum::binary-size(4), _rest::binary-size(28)>> = versioned_data_val |> hash(:sha256) |> hash(:sha256)
    checksum
  end


end
