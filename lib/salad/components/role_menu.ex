defmodule Salad.Components.RoleMenu do
  @moduledoc false
  use Salad.CommandSystem.Component, type: :select_menu
  import Bitwise
  require Logger
  alias Nostrum.Api

  def run(ev, role_group_id) do
    role_group_id = String.to_integer(role_group_id)
    %{data: %{values: selection}} = ev
    selection = Enum.map(selection, &String.to_integer/1)
    {:ok} = Api.create_interaction_response(ev, %{type: 5, data: %{flags: 1 <<< 6}})

    with role_group when not is_nil(role_group) <- Salad.Repo.RoleGroup.get(role_group_id),
         group_roles <- Enum.map(role_group.roles, & &1.id),
         # Make sure that any selected roles are only in the role group, and
         # that they're not already given to the user.
         roles_to_add <-
           MapSet.intersection(MapSet.new(group_roles), MapSet.new(selection)),
         # Roles the user has that are part of the group, and not in the new selection.
         roles_to_remove <-
           Enum.filter(ev.member.roles, fn r -> r in group_roles and r not in selection end),
         # Remove non-selected roles
         :ok <-
           Enum.each(roles_to_remove, fn r ->
             Api.remove_guild_member_role(ev.guild_id, ev.user.id, r, "Role menu removal")
           end),
         # Add selected roles
         :ok <-
           Enum.each(roles_to_add, fn r ->
             Api.add_guild_member_role(ev.guild_id, ev.user.id, r, "Role menu addition")
           end) do
      Api.edit_interaction_response(ev.token, %{
        content: "Your roles have been updated!"
      })
    else
      err ->
        # TODO: proper logging errors
        Logger.error(err)

        Api.edit_interaction_response(ev.token, %{
          content: "Something broke! Let an admin know or whatever."
        })
    end
  end
end
