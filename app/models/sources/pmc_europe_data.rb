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

class PmcEuropeData < Source

  def get_data(article, options={})

    # We need to have the PMID for this article, and we let the pub_med source fetch it
    return  { :events => [], :event_count => nil } if article.pub_med.blank?

    query_url = get_query_url(article)
    result = get_json(query_url, options)

    if result.nil?
      nil
    else
      event_count = result["hitCount"]

      if result["dbCountList"]
        events = result["dbCountList"]["db"].inject({}) { |hash, db| hash.update(db["dbName"] => db["count"]) }
      else
        events = nil
      end

      event_metrics = { :pdf => nil,
                        :html => nil,
                        :shares => nil,
                        :groups => nil,
                        :comments => nil,
                        :likes => nil,
                        :citations => event_count,
                        :total => event_count }

      { events: events,
        events_url: "http://europepmc.org/abstract/MED/#{article.pub_med}#fragment-related-bioentities",
        event_count: event_count,
        event_metrics: event_metrics }
    end
  end

  def get_query_url(article)
    url % { :pub_med => article.pub_med } unless article.pub_med.blank?
  end

  def get_config_fields
    [{:field_name => "url", :field_type => "text_area", :size => "90x2"}]
  end

  def url
    config.url || "http://www.ebi.ac.uk/europepmc/webservices/rest/MED/%{pub_med}/databaseLinks//1/json"
  end

end