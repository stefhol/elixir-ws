defmodule BackendWeb.ExampleChannel do
  alias Backend.CacheManager
  use Phoenix.Channel
  require Logger

  def join("room:" <> room_id, _params, socket) do
    guest_id = socket.assigns.guest_id
    Logger.info("Guest #{guest_id} joined room: #{room_id}")
    {:ok, assign(socket, :room_id, room_id)}
  end

  def handle_in("new_msg", %{"body" => body}, socket) do
    room_id = socket.assigns.room_id

    CacheManager.put(room_id, body)

    BackendWeb.Endpoint.broadcast!("room:" <> room_id, "new_msg", %{body: body, sender: "system"})
    {:noreply, socket}
  end

  def rename("user", %{"name" => value}, socket) do
    guest_id = socket.assigns.guest_id

    CacheManager.put(guest_id, value)

    BackendWeb.Endpoint.broadcast!("user", "change", %{
      response: "new name: " <> value,
      sender: "system"
    })

    {:noreply, socket}
  end
end
