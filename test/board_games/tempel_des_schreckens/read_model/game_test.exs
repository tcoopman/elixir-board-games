defmodule BoardGames.TempelDesSchreckens.ReadModel.GameTest do
  use BoardGames.InMemoryEventStoreCase
  use BoardGames.AggregateCase, aggregate: BoardGames.TempelDesSchreckens, async: false

  alias BoardGames.TempelDesSchreckens.ReadModel.Game
  alias BoardGames.ReadModel.Player

  setup do
    game_id = UUID.uuid4()
    Game.Supervisor.start_event_handler(game_id)
    pid = Game.Supervisor.state_by_game_id(game_id)

    [game_id: game_id, pid: pid]
  end

  describe "A game waiting for players" do
    test "should model a valid game", %{game_id: game_id, pid: pid} do
      {events, _opts} = BoardGames.Test.Stories.waiting_for_players(game_id: game_id)

      handle_events(pid, events)

      assert Game.State.status(game_id) == :waiting_for_players
      assert_all(Game.State.players(game_id), fn %Player{} ->
        true
      end)
    end

  end

  describe "Allowed actions" do
    test "when waiting for players and not joined", %{game_id: game_id, pid: pid} do
      {events, _opts} = BoardGames.Test.Stories.waiting_for_players(game_id: game_id)
      player_id = "not joined"

      handle_events(pid, events)

      assert Game.State.allowed_actions(game_id, player_id) == [:join]
    end

    test "waiting for players and joined", %{game_id: game_id, pid: pid} do
      {events, opts} = BoardGames.Test.Stories.waiting_for_players(game_id: game_id)
      player_id = Keyword.fetch!(opts, :player_id)

      handle_events(pid, events)

      assert Game.State.allowed_actions(game_id, player_id) == [:cancel]
    end

    test "game can be started and not joined", %{game_id: game_id, pid: pid} do
      {events, _opts} = BoardGames.Test.Stories.can_be_started(game_id: game_id)
      player_id = "not joined"

      handle_events(pid, events)

      assert Game.State.allowed_actions(game_id, player_id) == [:join]
    end

    test "game can be started and joined", %{game_id: game_id, pid: pid} do
      {events, opts} = BoardGames.Test.Stories.can_be_started(game_id: game_id)
      player_id = Keyword.fetch!(opts, :player_id)

      handle_events(pid, events)

      assert Game.State.allowed_actions(game_id, player_id) == [:cancel, :start]
    end

  end

  defp handle_events(pid, events), do: Enum.each(events, &Game.State.handle_event(pid, &1))

  defp assert_all(items, fun) do
    assert Enum.count(items) > 0
    assert Enum.all?(items, &fun.(&1))
  end
end
