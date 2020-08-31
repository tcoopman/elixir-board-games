defmodule BoardGames.TempelDesSchreckens.ReadModel.GameTest do
  use BoardGames.InMemoryEventStoreCase
  use BoardGames.AggregateCase, aggregate: BoardGames.TempelDesSchreckens, async: false

  alias BoardGames.TempelDesSchreckens.ReadModel.Game
  setup do
    game_id = UUID.uuid4()
    Game.Supervisor.start_event_handler(game_id)
    {:ok, pid} = Game.Supervisor.state_by_game_id(game_id)

    [game_id: game_id, pid: pid]
  end

  test "Game does not exist" do
    assert {:error, :game_not_found} = Game.Supervisor.state_by_game_id("invalid_id")
  end

  describe "A game waiting for players" do
    test "should model a valid game", %{game_id: game_id, pid: pid} do
      name = "Awesome name"
      {events, _opts} = BoardGames.Test.Stories.waiting_for_players(game_id: game_id, game_name: name)

      handle_events(pid, events)

      assert %Game.State{} = Game.State.get(game_id)
    end
  end

  describe "Allowed actions" do
    test "when waiting for players and not joined", %{game_id: game_id, pid: pid} do
      {events, _opts} = BoardGames.Test.Stories.waiting_for_players(game_id: game_id)
      player_id = "not joined"

      handle_events(pid, events)

      assert allowed_actions(game_id, player_id) == [:join]
    end

    test "waiting for players and joined", %{game_id: game_id, pid: pid} do
      {events, opts} = BoardGames.Test.Stories.waiting_for_players(game_id: game_id)
      player_id = Keyword.fetch!(opts, :player_id)

      handle_events(pid, events)

      assert allowed_actions(game_id, player_id) == [:cancel]
    end

    test "game can be started and not joined", %{game_id: game_id, pid: pid} do
      {events, _opts} = BoardGames.Test.Stories.can_be_started(game_id: game_id)
      player_id = "not joined"

      handle_events(pid, events)

      assert allowed_actions(game_id, player_id) == [:join]
    end

    test "game can be started and joined", %{game_id: game_id, pid: pid} do
      {events, opts} = BoardGames.Test.Stories.can_be_started(game_id: game_id)
      player_id = Keyword.fetch!(opts, :player_id)

      handle_events(pid, events)

      assert allowed_actions(game_id, player_id) == [:cancel, :start]
    end

    test "game has the maximum number of players", %{game_id: game_id, pid: pid} do
      {events, _opts} = BoardGames.Test.Stories.with_maximum_number_of_players_joined(game_id: game_id)
      player_id = "not joined"

      handle_events(pid, events)

      assert allowed_actions(game_id, player_id) == []
    end
  end

  defp handle_events(pid, events), do: Enum.each(events, &Game.State.handle_event(pid, &1))

  defp allowed_actions(game_id, player_id) do
    Game.State.get(game_id)
    |> Game.State.allowed_actions(player_id)
    |> MapSet.to_list()
  end
end
