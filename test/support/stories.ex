defmodule BoardGames.Test.Stories do
  alias BoardGames.TempelDesSchreckens.Event

  def waiting_for_players(opts \\ []) do
    [
      &game_created/1,
      &joined_game/1,
      &joined_game/1
    ]
    |> create_events(opts)
  end

  def can_be_started(opts \\ []) do
    [
      &game_created/1,
      &joined_game/1,
      &joined_game/1,
      &joined_game/1,
      &game_can_be_started/1
    ]
    |> create_events(opts)
  end

  def with_maximum_number_of_players_joined(opts \\ []) do
    [
      &game_created/1,
      &joined_game/1,
      &joined_game/1,
      &joined_game/1,
      &game_can_be_started/1,
      &joined_game/1,
      &joined_game/1,
      &joined_game/1,
      &joined_game/1,
      &joined_game/1,
      &joined_game/1,
      &joined_game/1,
      &maximum_number_of_players_joined/1
    ]
    |> create_events(opts)
  end

  def game_in_progress_with_3_players(opts \\ []) do
    [
      &game_created/1,
      &joined_game/1,
      &joined_game/1,
      &joined_game/1,
      &game_can_be_started/1,
      &game_started/1,
      &roles_dealt/1,
      &received_key/1,
      &round_started/1,
      &rooms_dealt/1
    ]
    |> create_events(opts)
  end

  defp game_created(opts) do
    game_id = Keyword.fetch!(opts, :game_id)
    game_name = Keyword.fetch!(opts, :game_name)

    {%Event.GameCreated{
       game_id: game_id,
       name: game_name
     }, opts}
  end

  defp joined_game(opts) do
    game_id = Keyword.fetch!(opts, :game_id)
    {player_id, opts} = Keyword.pop_first(opts, :player_id)

    {%Event.JoinedGame{
       game_id: game_id,
       player_id: player_id
     }, opts}
  end

  defp game_can_be_started(opts) do
    game_id = Keyword.fetch!(opts, :game_id)

    {%Event.GameCanBeStarted{
       game_id: game_id
     }, opts}
  end

  defp game_started(opts) do
    game_id = Keyword.fetch!(opts, :game_id)

    {%Event.GameStarted{
       game_id: game_id
     }, opts}
  end

  defp roles_dealt(opts) do
    game_id = Keyword.fetch!(opts, :game_id)

    {%Event.RolesDealt{
       game_id: game_id,
       roles: %{}
     }, opts}
  end

  defp received_key(opts) do
    game_id = Keyword.fetch!(opts, :game_id)

    {%Event.ReceivedKey{
       game_id: game_id,
       player_id: "Player1"
     }, opts}
  end

  defp round_started(opts) do
    game_id = Keyword.fetch!(opts, :game_id)

    {%Event.RoundStarted{
       game_id: game_id
     }, opts}
  end


  defp rooms_dealt(opts) do
    game_id = Keyword.fetch!(opts, :game_id)

    {%Event.RoomsDealt{
       game_id: game_id,
       rooms: %{
         "Player1" => ["treaure" , "empty" , "empty" , "trap" , "empty"],
         "Player2" => ["treaure" , "empty" , "empty" , "trap" , "empty"],
         "Player3" => ["treaure" , "empty" , "empty" , "trap" , "empty"],
       }
     }, opts}
  end

  defp maximum_number_of_players_joined(opts) do
    game_id = Keyword.fetch!(opts, :game_id)

    {%Event.MaximumNumberOfPlayersJoined{
       game_id: game_id
     }, opts}
  end

  defp create_events(events, opts) do
    initial_opts = set_opts(opts)

    {events, _opts} =
      Enum.reduce(events, {[], initial_opts}, fn fun, {events, opts} ->
        {event, opts} = fun.(opts)
        {[event | events], opts}
      end)

    {Enum.reverse(events), initial_opts}
  end

  defp set_opts(opts) do
    players = for i <- 1..10, do: {:player_id, "Player#{i}"}

    opts =
      opts
      |> Keyword.put_new(:game_id, UUID.uuid4())
      |> Keyword.put_new(:game_name, "Awesome game of tempel des schreckens")

    Keyword.merge(opts, players)
  end
end
