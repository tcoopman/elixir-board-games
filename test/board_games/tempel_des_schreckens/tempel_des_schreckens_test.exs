defmodule BoardGames.TempelDesSchreckensTest do
  use BoardGames.InMemoryEventStoreCase
  use BoardGames.AggregateCase, aggregate: BoardGames.TempelDesSchreckens, async: true

  import Commanded.Assertions.EventAssertions

  alias BoardGames.TempelDesSchreckens.{Command, Event}

  test "Create a new game" do
    :ok =
      BoardGames.App.dispatch(%Command.CreateGame{
        player_id: "player_id",
        game_id: "game_id",
        name: "the game name"
      })

    assert_receive_event(
      BoardGames.App,
      Event.GameCreated,
      fn event ->
        assert event.game_id == "game_id"
        assert event.name == "the game name"
      end
    )

    assert_receive_event(
      BoardGames.App,
      Event.JoinedGame,
      fn event ->
        assert event.game_id == "game_id"
        assert event.player_id == "player_id"
      end
    )
  end

  test "Try to create a game with an empty name" do
    command = %Command.CreateGame{
      player_id: "player_id",
      game_id: "game_id",
      name: ""
    }

    assert_error(command, {:error, :invalid_name})
  end

  describe "Join a game" do
    test "that is not yet created" do
      command = %Command.JoinGame{
        player_id: "player_id",
        game_id: "game_id"
      }

      assert_error(command, {:error, :game_is_not_in_progress})
    end

    test "that is waiting for people" do
      game_id = "game id"
      player_id = "player 1"

      assert_events(
        [
          %Event.GameCreated{
            game_id: game_id,
            name: "some game"
          }
        ],
        %Command.JoinGame{
          player_id: player_id,
          game_id: game_id
        },
        %Event.JoinedGame{
          game_id: game_id,
          player_id: player_id
        }
      )
    end

    test "that has the 9 players" do
      game_id = "game id"
      player_id = "player 10"

      current_players = for i <- 1..9, do: %Event.JoinedGame{game_id: game_id, player_id: "player_#{i}"}

      assert_events(
        [
          %Event.GameCreated{
            game_id: game_id,
            name: "some game"
          }
        ] ++ current_players,
        %Command.JoinGame{
          player_id: player_id,
          game_id: game_id
        },
        %Event.JoinedGame{
          game_id: game_id,
          player_id: player_id
        }
      )
    end

    test "that has the maximum of players already" do
      game_id = "game id"
      player_id = "player 10"

      current_players = for i <- 1..10, do: %Event.JoinedGame{game_id: game_id, player_id: "player_#{i}"}

      assert_error(
        [
          %Event.GameCreated{
            game_id: game_id,
            name: "some game"
          }
        ] ++ current_players,
        %Command.JoinGame{
          player_id: player_id,
          game_id: game_id
        },
        {:error, :max_number_of_players_reached}
      )
    end
  end
end
