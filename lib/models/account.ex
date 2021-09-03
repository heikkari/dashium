defmodule Models.Account do
  alias Models.User, as: User

  @spec auth(integer, binary) :: boolean
  def auth(user_id, gjp) when is_integer(user_id) and is_binary(gjp) do
    case Mongo.find_one(:mongo, "users", %{ _id: user_id }) do
      nil -> false
      document -> case check_pass(document, Utils.gjp(gjp, true)) do
        { :error, _ } -> false
        { :ok, _ } -> true
      end
    end
  end

  def check_pass(document, password) when is_binary(password) do
    user = User.new(document)

    case Argon2.check_pass(%{ password_hash: user.password }, password) do
      { :error, _ } -> { :error, false }
      { :ok, _ } -> { :ok, user }
    end
  end

  @spec login(binary, binary) :: { :error, boolean } | Integer
  def login(username, password) when is_binary(username) and is_binary(password) do
    case Mongo.find_one(:mongo, "users", %{ username: username }) do
      nil -> { :error, true }
      document -> check_pass(document, password)
    end
  end

  @doc """
    Inserts a `User` struct into the database.
  """
  def add(user) do
    { result, _ } = Mongo.insert_one(:mongo, "users", Map.from_struct user)
    result === :ok
  end

  @doc """
    Creates a new account if it doesn't exist already. Returns an HTTP status code along with a
    regular GD error (or success) code.
  """
  @spec register(binary, binary, binary) :: { 200 | 409 | 500, -2 | -3 | -1 | 1 }
  def register(email, username, password)
    when is_binary(email) and is_binary(username) and is_binary(password)
  do
    # Check if any users share the same e-mail or password.
    # If no error was found, `error_code` will be nil
    try do
      error_code =
        Enum.map(
          [ [ %{ username: username }, -2 ], [ %{ email: email }, -3 ] ],
          fn [criteria | [err | _]] ->
            # If more than one result was found, return the error code.
            # Otherwise, return a 0.
            if (Mongo.find(:mongo, "users", criteria) |> Enum.to_list() |> length) > 0, do: err, else: 0
          end
        )
          |> Enum.filter(&(&1 !== 0))
          |> List.first

      # Create a `User` struct
      %{ password_hash: hash } = Argon2.add_hash(password)
      user = %User { email: email, username: username, password: hash, _id: Utils.gen_id() }

      case error_code do
        nil -> if add(user), do: { 200, 1 }, else: { 500, -1 }
        error_code -> { 409, error_code }
      end
    rescue
      Protocol.UndefinedError -> { 500, -1 }
    end
  end

end
