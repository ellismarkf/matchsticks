defmodule Matchsticks.GameSupervisor do
  use DynamicSupervisor
  alias Matchsticks.GameServer

  def start_game(id) do
    DynamicSupervisor.start_child(__MODULE__, {GameServer, id})
  end

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
