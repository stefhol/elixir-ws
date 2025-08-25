defmodule BackendWeb.ExampleSocket do
  use Phoenix.Socket

  require Logger

  ## Channels
  channel "room:*", BackendWeb.ExampleChannel
  # ...

  def connect(params, socket, connect_info) do
    # Logger.debug("ExampleSocket.connect: Full connect_info: #{inspect(socket, pretty: true)}")

    #
    # Logger.debug(
    #   "ExampleSocket.connect: Raw request headers from connect_info: #{inspect(connect_info.req_headers)}"
    # )

    guest_token = params["guest_token"]

    # guest_token = guest_token || Map.get(connect_info.session, :guest_token)

    case guest_token do
      nil ->
        Logger.warning(
          "WebSocket connection rejected: No guest_token found in URL params or session."
        )

        :error

      token_to_verify ->
        Logger.debug("ExampleSocket.connect: Full connect_info: #{inspect(socket, pretty: true)}")

        hi =
          Phoenix.Token.verify(
            socket,
            "nbcu8xxWV8Wc2rzzvNfmQBGso4Lo6JN9Eem4qCqWJHNaMCC4xL6FP9MTRF7tijBa6nVG9vR9DeqecmFHoAjC2r",
            token_to_verify
          )

        Logger.info(hi)
        # Verify the token using the secret from the endpoint's Plug.Session
        # max_age should match your session/token's intended lifetime
        case Phoenix.Token.verify(
               socket,
               "nbcu8xxWV8Wc2rzzvNfmQBGso4Lo6JN9Eem4qCqWJHNaMCC4xL6FP9MTRF7tijBa6nVG9vR9DeqecmFHoAjC2r",
               token_to_verify
             ) do
          {:ok, verified_guest_id} ->
            Logger.info("WebSocket authenticated for guest ID: #{verified_guest_id}")
            # Assign the verified guest_id to the socket for later use in channels
            {:ok, assign(socket, :guest_id, verified_guest_id)}

          {:error, reason} ->
            Logger.warning(
              "WebSocket connection rejected: Guest token verification failed: #{inspect(reason)}"
            )

            # Reject on verification failure
            :error
        end
    end
  end

  def id(_socket), do: "socket:anonymous"
end
