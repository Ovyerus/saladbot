defmodule Salad.Components.Role do
  @moduledoc false
  use Salad.CommandSystem.Component, type: :button
  use Bitwise
  require Logger

  def run(ev, role) do
    role = String.to_integer(role)

    # TODO: verify with db to ensure its not old role?

    if role in ev.member.roles do
      case Api.remove_guild_member_role(ev.guild_id, ev.user.id, role, "Role menu removal") do
        {:ok} ->
          Api.create_interaction_response(ev, %{
            type: 4,
            data: %{
              content:
                "Successfully removed <@&#{role}>. Click the button again if you want it back.",
              flags: 1 <<< 6
            }
          })

        err ->
          # TODO: handle position issues
          Logger.error("Failed to remove role #{role} for #{ev.guild_id}: #{inspect(err)}")

          Api.create_interaction_response(ev, %{
            type: 4,
            data: %{content: "Failed to remove the role. Try again later.", flags: 1 <<< 6}
          })
      end
    else
      case Api.add_guild_member_role(ev.guild_id, ev.user.id, role, "Role menu addition") do
        {:ok} ->
          Api.create_interaction_response(ev, %{
            type: 4,
            data: %{
              content:
                "Successfully added <@&#{role}>. Click the button again if you want it removed.",
              flags: 1 <<< 6
            }
          })

        err ->
          Logger.error("Failed to add role #{role} for #{ev.guild_id}: #{inspect(err)}")

          Api.create_interaction_response(ev, %{
            type: 4,
            data: %{content: "Failed to add the role. Try again later.", flags: 1 <<< 6}
          })
      end
    end
  end
end
