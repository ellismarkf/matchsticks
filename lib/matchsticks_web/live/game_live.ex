defmodule MatchsticksWeb.GameLive do
  use MatchsticksWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, rows: [1,3,5,7], removed: MapSet.new(), selected: MapSet.new(), show_modal: false, game_over: false)}
  end

  def handle_event("select", %{"pos" => pos}, socket) do
    selected = if MapSet.member?(socket.assigns.selected, pos) do
      MapSet.delete(socket.assigns.selected, pos)
    else
      MapSet.put(socket.assigns.selected, pos)
    end
    {:noreply, assign(socket, selected: selected)}
  end

  def handle_event("commit", _unsigned_params, socket) do
    removed = MapSet.union(socket.assigns.removed, socket.assigns.selected)
    remaining = Enum.sum(socket.assigns.rows) - MapSet.size(removed)
    socket = assign(socket, removed: removed, selected: MapSet.new())
    case remaining do
      0 ->
        {:noreply,
          socket
            |> assign(show_modal: true, game_over: true)}
      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("reset", _unsigned_params, socket) do
    {:noreply, assign(socket, rows: [1,3,5,7], removed: MapSet.new(), selected: MapSet.new(), show_modal: false, game_over: false)}
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
      <div class="bg-green-400 h-screen w-screen flex items-center justify-center">
        <div>
        <section class="inline-flex justify-center">
          <button class="border-solid border-green-50 border-4 text-green-50 p-4 mx-16 shadow-hard">p1</button>
          <button class="border-solid border-green-50 border-4 text-green-50 p-4 mx-16 shadow-hard">p2</button>
        </section>
        <section class="flex-col justify-center items-center mt-16">
          <div :for={row <- @rows} class="flex justify-center self-center mt-4">
            <.stick :for={n <- 1..row} phx-value-pos={"#{row}-#{n}"} phx-click="select" selected={MapSet.member?(@selected, "#{row}-#{n}")} removed={MapSet.member?(@removed, "#{row}-#{n}")} allowed={Enum.all?(@selected, fn pos -> Integer.to_string(row) == String.at(pos, 0) end)}>
              <%= n %>
            </.stick>
          </div>
        </section>
        <section class="mt-16">

          <button disabled={not @game_over and MapSet.size(@selected) == 0} phx-click={if @game_over, do: "reset", else: "commit"} class="border-solid border-green-50 border-4 text-green-50 p-4 shadow-hard disabled:opacity-50">
            <%= if @game_over, do: "Reset", else: "End turn" %>
          </button>
        </section>
        </div>
      </div>
      <.modal id="game_over_modal" :if={@show_modal} show={@show_modal} on_confirm={JS.push("reset")}>
        <:title>Game over!</:title>
        Play again?
        <:confirm>OK</:confirm>
        <:cancel>Cancel</:cancel>
      </.modal>
    """
  end
end
