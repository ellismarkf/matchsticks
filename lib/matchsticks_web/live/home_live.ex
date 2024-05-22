defmodule MatchsticksWeb.HomeLive do
  use MatchsticksWeb, :live_view

  def mount(_, _, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1 class="text-white text-xl text-shadow">matchsticks</h1>
    <.link navigate={~p"/play/#{System.system_time(:microsecond)}"}>New Game</.link>
    """
  end
end
