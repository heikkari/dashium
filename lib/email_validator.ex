defmodule EmailValidator do

  # ensure that the email looks valid
  def validate_email(email) when is_binary(email) do
    case Regex.run(~r/^[\w.!#$%&’*+\-\/=?\^`{|}~]+@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*$/i, email) do
      nil -> false
      [email | _] ->
        try do
          Regex.run(~r/(\w+)@([\w.]+)/, email) |> validate_email
        rescue
          _ -> false
        end
    end
  end

  # check the email against a list of accepted domains, then make check if it is unique
  def validate_email([_, _, host]) do
    accepted_domains = Application.get_env(:app, :accepted_email_domains)
    host in accepted_domains
  end
end
