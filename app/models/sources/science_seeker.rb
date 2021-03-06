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

class ScienceSeeker < Source

  def get_data(article, options={})

    # Check that article has DOI
    return  { :events => [], :event_count => nil } if article.doi.blank?

    query_url = get_query_url(article)
    result = get_xml(query_url, options)

    # Check that ScienceSeeker has returned something, otherwise an error must have occured
    return nil if result.nil?

    events = []
    result.remove_namespaces!
    result.xpath("//entry").each do |entry|
      event = Hash.from_xml(entry.to_s)
      event = event['entry']
      events << { :event => event, :event_url => event['link']['href'] }
    end

    events_url = "http://scienceseeker.org/posts/?filter0=citation&modifier0=doi&value0=#{article.doi}"
    event_metrics = { :pdf => nil,
                      :html => nil,
                      :shares => nil,
                      :groups => nil,
                      :comments => nil,
                      :likes => nil,
                      :citations => events.length,
                      :total => events.length }

    { :events => events,
      :events_url => events_url,
      :event_count => events.length,
      :event_metrics => event_metrics,
      :attachment => events.empty? ? nil : { :filename => "events.xml", :content_type => "text\/xml", :data => result.to_s }}
  end

  def get_config_fields
    [{:field_name => "url", :field_type => "text_area", :size => "90x2"}]
  end

  def url
    config.url || "http://scienceseeker.org/search/default/?type=post&filter0=citation&modifier0=doi&value0=%{doi}"
  end

  def staleness_year
    config.staleness_year || 1.month
  end

  def rate_limiting
    config.rate_limiting || 1000
  end

end
