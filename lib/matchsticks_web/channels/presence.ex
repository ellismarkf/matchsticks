defmodule MatchsticksWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](https://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence,
    otp_app: :matchsticks,
    pubsub_server: Matchsticks.PubSub

  def init(_opts) do
    {:ok, %{}}
  end

  def handle_metas(topic, %{joins: joins, leaves: leaves}, presences, state) do
    for {id, presence} <- joins do
      user_data = %{id: id, metas: presence[:metas]}
      msg = {__MODULE__, {:join, user_data}}
      Phoenix.PubSub.local_broadcast(Matchsticks.PubSub, "proxy:#{topic}", msg)
    end

    for {id, _presence} <- leaves do
      metas =
        case Map.fetch(presences, id) do
          {:ok, presence_metas} -> presence_metas
          :error -> []
        end

      user_data = %{id: id, metas: metas}
      msg = {__MODULE__, {:leave, user_data}}
      Phoenix.PubSub.local_broadcast(Matchsticks.PubSub, "proxy:#{topic}", msg)
    end

    {:ok, state}
  end

  def list_players(id), do: list("game:" <> id) |> Enum.map(fn {id, presence} -> {id, presence} end)

  def track_player_joined(id, params), do: track(self(), "game:" <> id, params[:user_id], %{})

  def subscribe(id), do: Phoenix.PubSub.subscribe(Matchsticks.PubSub, "proxy:game:" <> id)

  def broadcast(id, msg), do: Phoenix.PubSub.local_broadcast(Matchsticks.PubSub, "proxy:game:" <> id, msg)
end
