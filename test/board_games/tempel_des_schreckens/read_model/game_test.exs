defmodule BoardGames.TempelDesSchreckens.ReadModel.GameTest do
  use BoardGames.InMemoryEventStoreCase
  use BoardGames.AggregateCase, aggregate: BoardGames.TempelDesSchreckens, async: false

  alias BoardGames.TempelDesSchreckens.ReadModel.Game
  alias BoardGames.TempelDesSchreckens.Event

  setup do
    game_id = UUID.uuid4()
    Game.Supervisor.start_event_handler(game_id)
    {:ok, pid} = Game.Supervisor.state_by_game_id(game_id)

    rooms_for_3_players = %{
      "Player1" => ["treasure", "empty", "treasure", "trap", "empty"],
      "Player2" => ["treasure", "empty", "empty", "empty", "trap"],
      "Player3" => ["treasure", "empty", "treasure", "empty", "empty"]
    }

    roles_for_3_players = %{
      "Player1" => "adventurer",
      "Player2" => "adventurer",
      "Player3" => "guardian"
    }

    [
      game_id: game_id,
      pid: pid,
      rooms_for_3_players: rooms_for_3_players,
      roles_for_3_players: roles_for_3_players
    ]
  end

  test "Game does not exist" do
    assert {:error, :game_not_found} = Game.Supervisor.state_by_game_id("invalid_id")
  end

  describe "A game waiting for players" do
    test "should model a valid game", %{game_id: game_id, pid: pid} do
      name = "Awesome name"

      {events, _opts} =
        BoardGames.Test.Stories.waiting_for_players(game_id: game_id, game_name: name)

      handle_events(pid, events)

      assert %{
               game_id: ^game_id,
               name: "Awesome name",
               status: :waiting_for_players,
               accepting_players: true,
               allowed_actions: allowed_actions,
               current_round: nil,
               joined_players: %{
                 "Player1" => %BoardGames.ReadModel.Player{},
                 "Player2" => %BoardGames.ReadModel.Player{}
               }
             } = Game.State.get(game_id, "some player")

      assert [:join] = MapSet.to_list(allowed_actions)
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
      {events, _opts} =
        BoardGames.Test.Stories.with_maximum_number_of_players_joined(game_id: game_id)

      player_id = "not joined"

      handle_events(pid, events)

      assert allowed_actions(game_id, player_id) == []
    end

    test "game is started and not joined", %{
      game_id: game_id,
      pid: pid,
      rooms_for_3_players: rooms_for_3_players,
      roles_for_3_players: roles_for_3_players
    } do
      {events, _opts} =
        BoardGames.Test.Stories.game_in_progress_with_3_players(
          game_id: game_id,
          rooms: rooms_for_3_players,
          roles: roles_for_3_players
        )

      player_id = "not joined"

      handle_events(pid, events)

      assert allowed_actions(game_id, player_id) == []
    end
  end

  describe "Playing a game" do
    test "received key but round not yet started", %{game_id: game_id, pid: pid} do
      {events, opts} = BoardGames.Test.Stories.can_be_started(game_id: game_id)
      handle_events(pid, events)

      player_id = Keyword.fetch!(opts, :player_id)

      new_events = [
        %Event.GameStarted{
          game_id: game_id
        },
        %Event.RolesDealt{
          game_id: game_id,
          roles: %{}
        },
        %Event.ReceivedKey{
          game_id: game_id,
          player_id: player_id
        }
      ]

      handle_events(pid, new_events)

      assert allowed_actions(game_id, player_id) == []
    end

    test "received key and round started", %{game_id: game_id, pid: pid} do
      {events, opts} = BoardGames.Test.Stories.can_be_started(game_id: game_id)
      handle_events(pid, events)

      player_id = Keyword.fetch!(opts, :player_id)

      new_events = [
        %Event.GameStarted{
          game_id: game_id
        },
        %Event.RolesDealt{
          game_id: game_id,
          roles: %{}
        },
        %Event.ReceivedKey{
          game_id: game_id,
          player_id: player_id
        },
        %Event.RoundStarted{
          game_id: game_id
        }
      ]

      handle_events(pid, new_events)

      assert %{
               current_round: 1,
               private: private_player_state
             } = Game.State.get(game_id, player_id)

      assert %Game.State.PrivatePlayerState{
               id: "Player1",
               can_open_room: true
             } = private_player_state
    end

    test "public player state", %{
      game_id: game_id,
      pid: pid,
      rooms_for_3_players: rooms_for_3_players,
      roles_for_3_players: roles_for_3_players
    } do
      {events, opts} =
        BoardGames.Test.Stories.game_in_progress_with_3_players(
          game_id: game_id,
          rooms: rooms_for_3_players,
          roles: roles_for_3_players
        )

      handle_events(pid, events)

      player_id = Keyword.fetch!(opts, :player_id)

      assert %{
               game_id: ^game_id,
               name: "Awesome game of tempel des schreckens",
               status: :playing,
               accepting_players: false,
               allowed_actions: allowed_actions,
               current_round: 1,
               joined_players: %{
                 "Player1" => %BoardGames.ReadModel.Player{},
                 "Player2" => %BoardGames.ReadModel.Player{},
                 "Player3" => %BoardGames.ReadModel.Player{}
               },
               state_of_players: state_of_players,
               private: private_player_state
             } = Game.State.get(game_id, player_id)

      assert %Game.State.PrivatePlayerState{
               id: "Player1",
               role: :adventurer,
               treasures: 2,
               empties: 2,
               traps: 1,
               can_open_room: true
             } = private_player_state

      assert [
               %Game.State.PublicPlayerState{
                 id: "Player1",
                 has_key: true,
                 rooms: [:closed, :closed, :closed, :closed, :closed]
               },
               %Game.State.PublicPlayerState{
                 id: "Player2",
                 has_key: false,
                 rooms: [:closed, :closed, :closed, :closed, :closed]
               },
               %Game.State.PublicPlayerState{
                 id: "Player3",
                 has_key: false,
                 rooms: [:closed, :closed, :closed, :closed, :closed]
               }
             ] = state_of_players
    end
  end

  defp handle_events(pid, events), do: Enum.each(events, &Game.State.handle_event(pid, &1))

  defp allowed_actions(game_id, player_id) do
    assert %{
             allowed_actions: allowed_actions
           } = Game.State.get(game_id, player_id)

    allowed_actions |> MapSet.to_list()
  end
end
