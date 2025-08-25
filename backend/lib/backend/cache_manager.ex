defmodule Backend.CacheManager do
  # Use the name you gave Redix in application.ex
  @redis_server :redix_cache
  require Logger

  @doc "Sets a key-value pair in Redis"
  def put(key, value) do
    # Redix.command!/2 sends a command and raises on error
    case Redix.command(@redis_server, ["SET", key, value]) do
      {:ok, _response} ->
        nil

      {:error, reason} ->
        Logger.error("Failed to set #{key} from Redis: #{inspect(reason)}")
        # Or re-raise, handle as appropriate
        nil
    end
  end

  @doc "Retrieves a value from Redis by key"
  def get(key) do
    case Redix.command(@redis_server, ["GET", key]) do
      # Key not found
      {:ok, nil} ->
        nil

      {:ok, value} ->
        value

      {:error, reason} ->
        Logger.error("Failed to get #{key} from Redis: #{inspect(reason)}")
        # Or re-raise, handle as appropriate
        nil
    end
  end

  @doc "Deletes a key from Redis"
  def delete(key) do
    Redix.command!(@redis_server, ["DEL", key])
  end

  # Example using EX (expire)
  def put_with_expiry(key, value, seconds) do
    Redix.command!(@redis_server, ["SETEX", key, seconds, value])
  end
end
