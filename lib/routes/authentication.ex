defmodule Routes.Authentication do
  use Routes.Base
  alias Models.Account, as: Account

  defp check_constraints_auth(required_fields, map) do
    fields = [
      # [ field, confirmation_field?, confirmation_error? ]
      [ "userName", nil, nil ],
      [ "password", "confirmPassword", -7 ],
      [ "email", "confirmEmail", -99 ]
    ]
      |> Enum.filter(fn [ head | _ ] -> Enum.member? required_fields, head end)

    Enum.map(fields, fn [ field, c_field, c_err ] ->
      # Get the maximum lengths for each field.
      [ min: [ mnl | [ min_err | _ ] ], max: [ mxl | [ max_err | _ ] ] ] =
        Application.get_env(:app, :auth_limits)[field]

      # ---
      len = byte_size(map[field])

      cond do
        len < mnl -> min_err
        len > mxl -> max_err
        c_field !== nil -> if map[field] !== map[c_field], do: c_err, else: 1
        true -> 1
      end
    end)
      |> Enum.filter(&(&1 !== 1))
  end

  defp on_valid_request(conn, required_fields, constraints, f) do
    # If the request is missing any parameters, send back a 400 with an error code of -1
    if Utils.is_field_missing required_fields, conn.params do
      send(conn, 400, "-1")
    else
      errors = check_constraints_auth constraints, conn.params

      if length(errors) !== 0 do
        [ head | _ ] = errors
        send(conn, 401, head |> Integer.to_string)
      else
        f.()
      end
    end
  end

  post "/database/accounts/registerGJAccount.php" do
    on_valid_request conn,
      ["email", "userName", "password", "confirmEmail", "confirmPassword"],
      [ "email", "userName", "password" ],
      fn ->
        email = conn.params["email"]

        if EmailValidator.validate_email(email) do
          { status, code } = Account.register(email, conn.params["userName"], conn.params["password"])
          send(conn, status, code |> Integer.to_string)
        else
          send(conn, 400, "-99")
        end
      end
  end

  post "/database/accounts/loginGJAccount.php" do
    fields = [ "userName", "password" ]

    on_valid_request conn, fields, fields, fn ->
      case Account.login(conn.params["userName"], conn.params["password"]) do
        { :error, b } -> send(conn, (if b, do: 500, else: 401), "-1")
        { :ok, user } -> send(conn, 200, user._id |> Integer.to_string)
      end
    end
  end

  match _ do
    send_resp(conn, 404, "Not found!")
  end
end
