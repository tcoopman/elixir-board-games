defmodule BoardGames.Test.Stories do
  alias BoardGames.TempelDesSchreckens.Event

  def waiting_for_players(opts \\ []) do
    opts = set_opts(opts)

    {[
       game_created(opts),
       joined_game(opts),
       joined_game(opts)
     ], opts}
  end

  defp game_created(opts) do
    game_id = Keyword.fetch!(opts, :game_id)
    game_name = Keyword.fetch!(opts, :game_name)

    %Event.GameCreated{
      game_id: game_id,
      name: game_name
    }
  end

  defp joined_game(opts) do
    game_id = Keyword.fetch!(opts, :game_id)
    player_id = Keyword.fetch!(opts, :player_id)

    %Event.JoinedGame{
      game_id: game_id,
      player_id: player_id
    }

  end

  defp set_opts(opts) do
    opts
    |> Keyword.put_new(:game_id, UUID.uuid4())
    |> Keyword.put_new(:game_name, "Awesome game of tempel des schreckens")
    |> Keyword.put_new(:player_id, UUID.uuid4())
  end
end
