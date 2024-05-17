defmodule MatchsticksWeb.GameLive do
  use MatchsticksWeb, :live_view
  alias Matchsticks.GameSupervisor
  alias Matchsticks.GameServer

  defp assign_game_server_pid(id, socket) do
    case GameSupervisor.start_game(id) do
      {:ok, game_server_pid} ->
        IO.puts("Started new game server with pid: " <> inspect(game_server_pid))
        assign(socket, game_server_pid: game_server_pid)
      {:error, {:already_started, game_server_pid}} ->
        IO.puts("Using existing game server with pid: " <> inspect(game_server_pid))
        assign(socket, game_server_pid: game_server_pid)
      result ->
        IO.puts("Something weird happened: " <> inspect(result))
        socket
    end
  end

  def mount(params, _session, socket) do
    GameServer.subscribe(params["id"])
    socket = assign_game_server_pid(params["id"], socket)
    socket = stream(socket, :players, [])
    socket =
      if connected?(socket) do
        MatchsticksWeb.Presence.track_player_joined(params["id"], %{ user_id: System.system_time(:microsecond)})
        MatchsticksWeb.Presence.subscribe(params["id"])
        stream(socket, :players, MatchsticksWeb.Presence.list_players(params["id"])
          |> Enum.map(fn {id, presence} -> %{id: id,metas: presence[:metas]} end))
        else
          socket
        end
    players_count =  length(MatchsticksWeb.Presence.list_players(params["id"]))
    socket = assign(socket, player_id: players_count)
    game_state = GameServer.get_state(socket.assigns.game_server_pid)
    {:ok, assign(socket, Map.from_struct(game_state))}
  end

  def handle_event("select", %{"pos" => pos}, socket) do
    GameServer.select({ socket.assigns.game_server_pid, pos })
    {:noreply, socket}
  end

  def handle_event("commit", _unsigned_params, socket) do
    GameServer.commit(socket.assigns.game_server_pid)
    {:noreply, socket}
  end

  def handle_event("reset", _unsigned_params, socket) do
    GameServer.reset(socket.assigns.game_server_pid)
    {:noreply, socket}
  end

  def handle_info({MatchsticksWeb.Presence, {:join, presence}}, socket) do
    {:noreply, stream_insert(socket, :players, presence)}
  end

  def handle_info({MatchsticksWeb.Presence, {:leave, presence}}, socket) do
    if presence.metas == [] do
      {:noreply, stream_delete(socket, :players, presence)}
    else
      {:noreply, stream_insert(socket, :players, presence)}
    end
  end

  def handle_info({:game_update, selected: selected}, socket) do
    {:noreply, assign(socket, selected: selected)}
  end

  def handle_info({:game_update, game_over: game_over_state}, socket) do
    {:noreply, assign(socket, Map.from_struct(game_over_state))}
  end

  def handle_info({:game_update, commit: game_state}, socket) do
    {:noreply, assign(socket, Map.from_struct(game_state))}
  end

  def handle_info({:game_update, reset: reset_state}, socket) do
    {:noreply, assign(socket, Map.from_struct(reset_state))}
  end

  defp is_allowed?(active_player, player_id, selected, row) do
    Enum.all?(selected, fn pos -> Integer.to_string(row) == String.at(pos, 0) end) and
      player_id == active_player
  end

  slot :inner_block, required: true
  attr :selected, :boolean, required: true
  attr :removed, :boolean, required: true
  attr :allowed, :boolean, required: true
  attr :rest, :global
  def stick(assigns) do
    ~H"""
    <button {@rest} disabled={@removed or not @allowed} class={"w-4 h-20 inline-block mx-4 shadow-hard bg-green-50 relative hover:-translate-y-1 #{if @selected, do: "-translate-y-1 bg-green-200"} text-green-50 #{if @removed, do: "opacity-0"} #{if @allowed, do: "cursor-pointer"} #{if not @allowed and not @removed, do: "opacity-50"} #{if not @allowed or @removed, do: "pointer-events-none"} transition-all"}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  def render(assigns) do
    ~H"""
        <section class="inline-flex justify-center items-center">
          <button class={"relative border-solid border-green-50 border-4 p-4 mx-16 shadow-hard #{if @active_player == 1, do: "text-green-50 -translate-y-2", else: "text-green-900"} transition-all"}>
            p1
            <span :if={@player_id == 1 and @active_player == @player_id} class="absolute -left-48 text-nowrap w-full inline-block whitespace-nowrap">Your turn</span>
          </button>
          <button class={"relative border-solid border-green-50 border-4 p-4 mx-16 shadow-hard #{if @active_player == 2, do: "text-green-50 -translate-y-2", else: "text-green-900"} transition-all"}>
            p2
            <span :if={@player_id == 2 and @active_player == @player_id} class="absolute -right-24 text-nowrap w-full inline-block whitespace-nowrap">Your turn</span>
          </button>
        </section>
        <section class="flex-col justify-center items-center mt-16">
          <div :for={row <- @rows} class="flex justify-center self-center mt-4">
            <.stick :for={n <- 1..row} phx-value-pos={"#{row}-#{n}"} phx-click="select" selected={MapSet.member?(@selected, "#{row}-#{n}")} removed={MapSet.member?(@removed, "#{row}-#{n}")} allowed={is_allowed?(@active_player, @player_id, @selected, row)}>
              <%= n %>
            </.stick>
          </div>
        </section>
        <section class="mt-16">
          <% is_disabled? = (@active_player != @player_id and not @game_over) or (not @game_over and MapSet.size(@selected) == 0) %>
          <button disabled={is_disabled?} phx-click={if @game_over, do: "reset", else: "commit"} class="border-solid border-green-50 border-4 text-green-50 p-4 shadow-hard disabled:opacity-0 relative disabled:translate-y-4 transition-all">
            <%= if @game_over, do: "Reset", else: "End turn" %>
          </button>
        </section>
        <ul id="players" phx-update="stream" class="absolute top-0 left-0" :if={Application.get_env(:matchsticks, :dev_routes)}>
          <li :for={{dom_id, %{id: id, metas: metas }} <- @streams.players} id={dom_id}><%= id %>(<%= length(metas) %>)</li>
        </ul>

      <.modal id="game_over_modal" :if={@game_over} show={@game_over} on_confirm={JS.push("reset")}>
        <:title>Game over!</:title>
        You <%= if @active_player ==@player_id, do: "won", else: "lost" %>.
        <:confirm>Play again</:confirm>
        <:cancel>Cancel</:cancel>
      </.modal>
    """
  end
end
