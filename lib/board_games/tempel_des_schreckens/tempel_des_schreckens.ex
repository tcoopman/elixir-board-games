defmodule BoardGames.TempelDesSchreckens do
  use TypedStruct
  use Magritte

  alias __MODULE__
  alias BoardGames.TempelDesSchreckens.{Event, Command}

  @type role :: :adventurer | :guardian
  @type status :: :waiting_for_players | :playing

  typedstruct do
    field :game_id, String.t()
    field :players, list(String.t()), default: []
    field :name, String.t()
    field :roles, list({String.t(), role()})
    field :status, status()
  end

  defguard is_non_empty_string?(str) when is_binary(str) and str != ""

  def execute(
        game,
        %Command.CreateGame{} = command
      ) do
    game
    |> Commanded.Aggregate.Multi.new()
    |> Commanded.Aggregate.Multi.execute(&create_game(&1, command.game_id, command.name))
    |> Commanded.Aggregate.Multi.execute(&join_game(&1, command.player_id))
  end

  def execute(game, %Command.JoinGame{player_id: player_id}),
    do: join_game(game, player_id)

  def execute(game, %Command.StartGame{}) do
    game
    |> Commanded.Aggregate.Multi.new()
    |> Commanded.Aggregate.Multi.execute(&start_game(&1))
    |> Commanded.Aggregate.Multi.execute(&deal_roles(&1))
    |> Commanded.Aggregate.Multi.execute(&give_key(&1))
    |> Commanded.Aggregate.Multi.execute(&start_round(&1))
    |> Commanded.Aggregate.Multi.execute(&deal_rooms(&1))
  end

  @spec apply(
          BoardGames.TempelDesSchreckens.t(),
          Event.GameCreated.t()
        ) ::
          BoardGames.TempelDesSchreckens.t()
  def apply(%TempelDesSchreckens{} = game, %Event.GameCreated{
        game_id: game_id,
        name: name
      }) do
    %{game | game_id: game_id, name: name, status: :waiting_for_players}
  end

  def apply(
        %TempelDesSchreckens{players: players} = game,
        %Event.JoinedGame{
          player_id: player_id
        }
      ) do
    %{game | players: [player_id | players]}
  end

  def apply(%TempelDesSchreckens{} = game, %Event.GameStarted{}) do
    %{game | status: :playing}
  end

  def apply(%TempelDesSchreckens{} = game, %Event.RolesDealt{
        roles: roles
      }) do
    %{game | roles: roles}
  end

  def apply(%TempelDesSchreckens{} = game, %Event.ReceivedKey{}) do
    game
  end

  def apply(%TempelDesSchreckens{} = game, %Event.RoomsDealt{}) do
    game
  end

  def apply(%TempelDesSchreckens{} = game, %Event.RoundStarted{}) do
    game
  end

  def apply(%TempelDesSchreckens{} = game, %Event.GameCanBeStarted{}) do
    game
  end

  defp create_game(%TempelDesSchreckens{}, _, name) when not is_non_empty_string?(name),
    do: {:error, :invalid_name}

  defp create_game(%TempelDesSchreckens{status: status}, _, _name) when not is_nil(status),
    do: {:error, :game_already_exists}

  defp create_game(%TempelDesSchreckens{players: []}, id, name) do
    %Event.GameCreated{
      game_id: id,
      name: name
    }
  end

  defp join_game(%TempelDesSchreckens{game_id: game_id}, _)
       when not is_non_empty_string?(game_id),
       do: {:error, :game_is_not_in_progress}

  defp join_game(%TempelDesSchreckens{players: players}, _)
       when length(players) >= 10,
       do: {:error, :max_number_of_players_reached}

  defp join_game(%TempelDesSchreckens{players: players} = game, player_id) do
    is_member = Enum.member?(players, player_id)
    number_of_players = Enum.count(players)

    if is_member do
      {:error, :player_already_joined}
    else
      if number_of_players == 2 do
        [
          %Event.JoinedGame{
            game_id: game.game_id,
            player_id: player_id
          },
          %Event.GameCanBeStarted{game_id: game.game_id}
        ]
      else
        %Event.JoinedGame{
          game_id: game.game_id,
          player_id: player_id
        }
      end
    end
  end

  defp start_game(%TempelDesSchreckens{status: status}) when status != :waiting_for_players,
    do: {:error, :game_already_started}

  defp start_game(%TempelDesSchreckens{players: players}) when length(players) < 3,
    do: {:error, :not_enough_players_joined}

  defp start_game(%TempelDesSchreckens{} = game) do
    %Event.GameStarted{game_id: game.game_id}
  end

  defp deal_roles(%TempelDesSchreckens{players: players} = game) do
    nb_of_players = Enum.count(players)

    {nb_of_adventures, nb_of_guardians} =
      case nb_of_players do
        3 -> {2, 2}
        4 -> {3, 2}
        5 -> {3, 2}
        6 -> {4, 2}
        7 -> {5, 3}
        8 -> {6, 3}
        9 -> {6, 3}
        10 -> {7, 4}
      end

    adventures = for _ <- 1..nb_of_adventures, do: :adventurer
    guardians = for _ <- 1..nb_of_guardians, do: :guardian
    initial_cards = adventures ++ guardians

    roles =
      initial_cards
      |> Enum.take_random(nb_of_players)
      |> Enum.zip(players, ...)

    %Event.RolesDealt{game_id: game.game_id, roles: roles}
  end

  defp give_key(%TempelDesSchreckens{players: players} = game) do
    player_with_key = players |> Enum.reverse() |> hd()

    %Event.ReceivedKey{
      game_id: game.game_id,
      player_id: player_with_key
    }
  end

  defp start_round(%TempelDesSchreckens{} = game) do
    %Event.RoundStarted{game_id: game.game_id}
  end

  defp deal_rooms(%TempelDesSchreckens{players: players} = game) do
    nb_of_players = Enum.count(players)

    {nb_of_treasures, nb_of_traps} =
      case nb_of_players do
        3 -> {5, 2}
        4 -> {6, 2}
        5 -> {7, 2}
        6 -> {8, 2}
        7 -> {7, 2}
        8 -> {8, 2}
        9 -> {9, 2}
        10 -> {10, 3}
      end

    treasures = for _ <- 1..nb_of_treasures, do: :treasure
    traps = for _ <- 1..nb_of_traps, do: :trap
    empty = for _ <- 1..(nb_of_players * 5 - nb_of_traps - nb_of_treasures), do: :empty
    initial_cards = traps ++ treasures ++ empty

    rooms = initial_cards |> Enum.shuffle() |> Enum.chunk_every(5)

    rooms =
      rooms
      |> Enum.zip(players, ...)

    %Event.RoomsDealt{game_id: game.game_id, rooms: rooms}
  end
end
