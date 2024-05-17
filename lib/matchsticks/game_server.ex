defmodule Matchsticks.GameServer do
  defmodule GameState do
    defstruct [:game_id, removed: MapSet.new(), selected: MapSet.new(), active_player: 1, rows: [1,3,5,7], game_over: false]
  end
  use GenServer, restart: :transient

  def select({pid, stick}) do
    GenServer.cast(pid, { :select, stick })
  end

  def commit(pid) do
    GenServer.cast(pid, :commit )
  end

  def reset(pid) do
    GenServer.cast(pid, :reset)
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  def subscribe(id) do
    Phoenix.PubSub.subscribe(Matchsticks.PubSub, "game:server:" <> id)
  end

  defp broadcast(id, update) do
    Phoenix.PubSub.broadcast(Matchsticks.PubSub, "game:server:" <> id, {:game_update, update})
  end

  def start_link(id) do
    GenServer.start_link(__MODULE__, %GameState{ game_id: id }, name: {:global, "game:server:" <> id})
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_cast(:reset, state) do
    reset_state = %GameState{ game_id: state.game_id }
    broadcast(state.game_id, reset: reset_state)
    {:noreply, reset_state}
  end

  def handle_cast(:commit, state) do
    removed = MapSet.union(state.removed, state.selected)
    remaining = Enum.sum(state.rows) - MapSet.size(removed)
    new_state = %{ state | removed: removed, selected: MapSet.new(), active_player: 3 - state.active_player}
    if remaining == 0 do
      game_over_state = %{ new_state | game_over: true }
      broadcast(state.game_id, game_over: game_over_state)
      {:noreply, game_over_state}
    else
      broadcast(state.game_id, commit: new_state)
      {:noreply, new_state}
    end
  end

  def handle_cast({:select, stick}, state) do
    selected = if MapSet.member?(state.selected, stick) do
      MapSet.delete(state.selected, stick)
    else
      MapSet.put(state.selected, stick)
    end
    broadcast(state.game_id, selected: selected)
    {:noreply, %{ state | selected: selected}}
  end
end
