# encoding: UTF-8

# $HeadURL$
# $Id$
#
# Copyright (c) 2009-2012 by Public Library of Science, a non-profit corporation
# http://www.plos.org/
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class SourceNotUpdatedError < Filter

  def run_filter(state)
    responses_by_source = ApiResponse.filter(state[:id]).group(:source_id).count
    source_ids = Source.where("state > ?",0).where("name != ?", 'pmc').pluck(:id)
    responses = source_ids.select { |source_id| !responses_by_source.has_key?(source_id) }

    if responses.count > 0
      responses = responses.map { |response| { source_id: response,
                                               message: "Source not updated for 24 hours" }}
      raise_alerts(responses)
    end

    responses.count
  end
end

module Exceptions
  class SourceNotUpdatedError < ApiResponseError; end
end