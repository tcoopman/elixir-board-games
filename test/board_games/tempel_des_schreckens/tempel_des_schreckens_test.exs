defmodule BoardGames.TempelDesSchreckensTest do
  use BoardGames.InMemoryEventStoreCase
  use BoardGames.AggregateCase, aggregate: BoardGames.Game, async: true

  import Commanded.Assertions.EventAssertions

  test "Create a new game" do
    :ok =
      BoardGames.App.dispatch(%BoardGames.Command.TempelDesSchreckens.CreateGame{
        player_id: "player_id",
        game_id: "game_id",
        name: "the game name",
      })

    assert_receive_event(BoardGames.App, BoardGames.Event.TempelDesSchreckens.GameCreated, fn event ->
      assert event.game_id == "game_id"
      assert event.player_id == "player_id"
      assert event.name == "the game name"
    end)
  end

  test "Try to create a game with an empty name" do
    command = %BoardGames.Command.TempelDesSchreckens.CreateGame{
        player_id: "player_id",
        game_id: "game_id",
        name: "",
      }

    assert_error(command, {:error, :invalid_name})
  end


end
