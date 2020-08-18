defmodule BoardGames.TempelDesSchreckensTest do
  use BoardGames.InMemoryEventStoreCase
  use BoardGames.AggregateCase, aggregate: BoardGames.TempelDesSchreckens, async: true

  import Commanded.Assertions.EventAssertions

  alias BoardGames.TempelDesSchreckens.{Command, Event}

  describe "Create a game" do
    test "that is valid" do
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

    test "with an empty name" do
      command = %Command.CreateGame{
        player_id: "player_id",
        game_id: "game_id",
        name: ""
      }

      assert_error(command, {:error, :invalid_name})
    end
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

      current_players =
        for i <- 1..9, do: %Event.JoinedGame{game_id: game_id, player_id: "player_#{i}"}

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

      current_players =
        for i <- 1..10, do: %Event.JoinedGame{game_id: game_id, player_id: "player_#{i}"}

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

  describe "Start a game" do
    test "that has enough players" do
      game_id = "game id"

      current_players =
        for i <- 1..3, do: %Event.JoinedGame{game_id: game_id, player_id: "player_#{i}"}

      assert_expectation(
        [
          %Event.GameCreated{
            game_id: game_id,
            name: "some game"
          }
        ] ++ current_players,
        %Command.StartGame{
          game_id: game_id
        },
        fn _state, events ->
          expectation_per_event(events, [
            &game_started/1,
            &roles_dealt/1,
            &received_key/1,
            &round_started/1,
            &rooms_dealt(&1, 5)
          ])
        end
      )
    end

    test "that has not enough players" do
      game_id = "game id"

      current_players =
        for i <- 1..2, do: %Event.JoinedGame{game_id: game_id, player_id: "player_#{i}"}

      assert_error(
        [
          %Event.GameCreated{
            game_id: game_id,
            name: "some game"
          }
        ] ++ current_players,
        %Command.StartGame{
          game_id: game_id
        },
        {:error, :not_enough_players_joined}
      )
    end

    test "that is already in progress" do
      game_id = "game id"

      current_players =
        for i <- 1..3, do: %Event.JoinedGame{game_id: game_id, player_id: "player_#{i}"}

      assert_error(
        [
          %Event.GameCreated{
            game_id: game_id,
            name: "some game"
          }
        ] ++ current_players ++ [%Event.GameStarted{game_id: game_id}],
        %Command.StartGame{
          game_id: game_id
        },
        {:error, :game_already_started}
      )
    end
  end

  defp expectation_per_event(events, expectations) do
    assert Enum.count(events) == Enum.count(expectations)

    Enum.zip(events, expectations)
    |> Enum.each(fn {event, expectation} -> assert expectation.(event) end)
  end

  defp game_started(%Event.GameStarted{}), do: true

  defp roles_dealt(%Event.RolesDealt{roles: roles}) do
    refute Enum.empty?(roles)

    assert Enum.each(roles, fn
             {_, :guardian} -> true
             {_, :adventurer} -> true
           end)
  end

  defp received_key(%Event.ReceivedKey{}), do: true

  defp round_started(%Event.RoundStarted{}), do: true

  defp rooms_dealt(%Event.RoomsDealt{rooms: rooms}, expected_nb_of_rooms) do
    refute Enum.empty?(rooms)

    assert Enum.each(rooms, fn
             {_, rooms} ->
               assert Enum.count(rooms) == expected_nb_of_rooms

               Enum.each(rooms, fn
                 :treasure -> true
                 :trap -> true
                 :empty -> true
               end)
           end)
  end
end
