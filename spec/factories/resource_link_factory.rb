#
# Copyright (C) 2018 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

module Factories
  def resource_link_model(overrides: {})
    params = {
      resource_link_id: overrides[:resource_link_id],
      context_external_tool: overrides.fetch(:with_context_external_tool) do |_|
        external_tool_model(context: overrides[:context], opts: overrides.fetch(:context_external_tool, {}))
      end
    }
    Lti::ResourceLink.create!(params)
  end
end