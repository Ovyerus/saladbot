defmodule Salad.Commands.Add do
  @moduledoc false
  require Logger
  import Bitwise
  use Salad.CommandSystem.Command
  alias Salad.{Repo, Util}

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
      },
      %Option{
        name: "icon",
        type: Option.Type.string(),
        description: "The emoji to display when users apply the role",
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
    %{
      "group" => %{value: group},
      "role" => %{value: role},
      "icon" => %{value: icon}
    } = ctx.options

    with role_group when role_group != nil <-
           Repo.RoleGroup.get_by_name_and_guild(group, ctx.guild_id),
         # Discord provides max of 25 buttons per message (5 cols x 5 rows), so
         # limit this so that we never go over that limit when syncing group
         # messages. Still more than convential reaction based menus though (20).
         true <- length(role_group.roles) < 25 || :limit_reached,
         true <- role.id != ctx.guild_id || :role_everyone,
         nil <- Enum.find(role_group.roles, fn r -> r.id == role.id end),
         true <- Util.emoji_or_custom_emote?(icon) || :icon_not_emoji,
         true <-
           Util.accessible_emoji?(icon, ctx.guild_id) || :icon_not_accessible,
         {icon_id, icon_name, icon_animated} <- Util.parse_emoji(icon),
         {:ok, _} <-
           Repo.Role.create(role.id, role_group.id, %{
             id: icon_id,
             name: icon_name,
             animated: icon_animated
           }),
         {:ok, _} <- Repo.RoleGroup.update(role_group) do
      reply(ctx, %{
        type: 4,
        data: %{
          content: "Successfully added #{role} to the \"#{group}\" group.",
          flags: 1 <<< 6
        }
      })
    else
      nil ->
        reply(ctx, %{
          type: 4,
          data: %{
            content: "A role group with that name does not exist.",
            flags: 1 <<< 6
          }
        })

      :limit_reached ->
        reply(ctx, %{
          type: 4,
          data: %{
            content:
              "This role group has reached the limit of 25 roles and is now full. " <>
                "Either remove some other roles, or crete a new group.",
            flags: 1 <<< 6
          }
        })

      :role_everyone ->
        reply(ctx, %{
          type: 4,
          data: %{
            content: "The role you provided should not be the `@everyone` role.",
            flags: 1 <<< 6,
            allowed_mentions: %{parse: []}
          }
        })

      %Repo.Role{} ->
        reply(ctx, %{
          type: 4,
          data: %{
            content: "That role is already a part of this group. Try picking another one.",
            flags: 1 <<< 6
          }
        })

      :icon_not_emoji ->
        reply(ctx, %{
          type: 4,
          data: %{
            content: "The icon provided must be an emoji or custom emote.",
            flags: 1 <<< 6
          }
        })

      :icon_not_accessible ->
        reply(ctx, %{
          type: 4,
          data: %{
            content:
              "The icon provided must be a default Discord emoji, or a custom emote from this server.",
            flags: 1 <<< 6
          }
        })

      {:error, %Ecto.Changeset{} = err} ->
        Logger.error("Failed to add role to group `#{group}`: #{inspect(err)}")

        reply(ctx, %{
          type: 4,
          data: %{
            content: "Failed to add the role to the group.",
            flags: 1 <<< 6
          }
        })
    end
  end
end
