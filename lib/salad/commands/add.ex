defmodule Salad.Commands.Add do
  @moduledoc false
  use Bitwise
  use Salad.CommandSystem.Command
  alias Salad.Repo

  @impl true
  def description, do: "Add a role to a role group"

  @impl true
  def predicates,
    do: [
      guild_only(),
      permissions([:manage_guild]),
      guild_setup()
    ]

  @impl true
  def options,
    do: [
      %Option{
        name: "group",
        type: Option.Type.string(),
        description: "The name of the group to add the role to",
        required: true,
        autocomplete: true
      },
      %Option{
        name: "role",
        type: Option.Type.role(),
        description: "The role to add to the group",
        required: true
      }
    ]

  @impl true
  def autocomplete(%{data: %{options: options}, guild_id: guild_id}) do
    opt = Enum.find(options, fn opt -> opt.focused end)

    case opt.name do
      "group" ->
        if(opt.value && opt.value != "",
          do: Repo.RoleGroup.search_for_guild(guild_id, opt.value, 25),
          else: Repo.RoleGroup.get_for_guild(guild_id, 25)
        )
        |> Enum.map(fn group -> %{name: group.name, value: group.name} end)

      _ ->
        []
    end
  end

  @impl true
  def run(ctx) do
    IO.inspect(ctx)

    reply(ctx, %{
      type: 4,
      data: %{
        content: "yoooo",
        flags: 1 <<< 6
      }
    })
  end
end
