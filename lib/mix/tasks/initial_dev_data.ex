defmodule Mix.Tasks.InitialDevData do
  use Mix.Task

  alias BoardGames.TempelDesSchreckens.Command

  @myself "Player3"

  @shortdoc "Setup initial development data"
  def run(_) do
    # This will start our application
    Mix.Task.run("app.start")

    # First game - 1 player joined
    play_game("1", "1 player joined here", ["Player1"])

    # Second game - 2 players joined
    play_game("2", "2 players joined here", ["Player1", "Player2"])

    # Third game - 3 players joined
    play_game("3", "3 players joined here (including you)", ["Player1", "Player2", @myself])

    # Forth game - 3 players joined
    play_game("4", "3 players joined here (excluding you)", ["Player1", "Player2", "Player4"])

    # Fifth game - 10 players joined
    players = for i <- 1..10, do: "Unknown_player#{i}"
    play_game("5", "10 players joined, excluding you", players)
  end

  defp play_game(game_id, game_name, players) do
    [player_id | players ] = players
    create_game = %Command.CreateGame{player_id: player_id, game_id: game_id, name: game_name}
    :ok = BoardGames.App.dispatch(create_game)
    Enum.each(players, fn player_id ->
      join_game = %Command.JoinGame{player_id: player_id, game_id: game_id}
      :ok = BoardGames.App.dispatch(join_game)
    end)
  end
end
