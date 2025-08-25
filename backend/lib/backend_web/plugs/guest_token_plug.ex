# lib/backend_web/plugs/guest_token_plug.ex
defmodule BackendWeb.GuestTokenPlug do
  import Plug.Conn
  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do

    conn = if not Map.has_key?(conn.private, :plug_session) do
      conn |> fetch_session() # Explicitly fetch the session
    else
      conn
    end

    current_guest_token = get_session(conn, :guest_token)

    if current_guest_token do
      Logger.debug("GuestTokenPlug: Existing guest_token found. No new token generated.")
      conn
    else
      guest_id = Ecto.UUID.generate() # Assumes Ecto is in deps or use Base.url_encode64(:crypto.strong_rand_bytes(32))
      guest_token = Phoenix.Token.sign(conn, "nbcu8xxWV8Wc2rzzvNfmQBGso4Lo6JN9Eem4qCqWJHNaMCC4xL6FP9MTRF7tijBa6nVG9vR9DeqecmFHoAjC2r", guest_id)

      Logger.debug("GuestTokenPlug: Generated new guest_id: #{guest_id}, guest_token: #{guest_token}")

      conn
      |> put_session(:guest_token, guest_token)
    end
  end
end
