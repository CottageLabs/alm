# encoding: UTF-8

# $HeadURL$
# $Id$
#
# Copyright (c) 2009-2013 by Public Library of Science, a non-profit corporation
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

class Pmc < Source

  # Format Pmc events for all articles as csv
  # Show historical data if options[:format] is used
  # options[:format] can be "html", "pdf" or "combined"
  # options[:month] and options[:year] are the starting month and year, default to last month
  def self.to_csv(options = {})

    if ["html","pdf","combined"].include? options[:format]
      view = "pmc_#{options[:format]}_views"
    else
      view = "pmc"
    end

    service_url = "#{CONFIG[:couchdb_url]}_design/reports/_view/#{view}"

    result = get_json(service_url, options)
    return nil if result.blank? || result["rows"].blank?

    if view == "pmc"
      CSV.generate do |csv|
        csv << ["doi", "html", "pdf", "total"]
        result["rows"].each { |row| csv << [row["key"], row["value"]["html"], row["value"]["pdf"], row["value"]["total"]] }
      end
    else
      dates = self.date_range(options).map { |date| "#{date[:year]}-#{date[:month]}" }

      CSV.generate do |csv|
        csv << ["doi"] + dates
        result["rows"].each { |row| csv << [row["key"]] + dates.map { |date| row["value"][date] || 0 }}
      end
    end
  end

  # Array of hashes in format [{ month: 12, year: 2013 },{ month: 1, year: 2014 }]
  # Provide starting month and year as input, otherwise defaults to last month
  def self.date_range(options = {})
    end_date = 1.month.ago.to_date

    if options[:month] && options[:year]
      start_date = Date.new(options[:year].to_i, options[:month].to_i, 1) rescue end_date
      start_date = end_date if start_date > end_date
    else
      start_date = end_date
    end

    dates = (start_date..end_date).map { |date| { month: date.month, year: date.year } }.uniq
  end

  def put_pmc_database
    put_alm_data(url)
  end

  # Retrieve usage stats in XML and store in /data directory. Returns nil if an error occured.
  def get_feed(month, year, options={})
    options[:source_id] = id

    journals_array = journals.split(",")
    journals_with_errors = []
    journals_array.each do |journal|
      feed_url = get_feed_url(month, year, journal)
      filename = "pmcstat_#{journal}_#{month}_#{year}.xml"

      if save_to_file(feed_url, filename, options).nil?
        Alert.create(:exception => "", :class_name => "Net::HTTPInternalServerError",
             :message => "PMC Usage stats for journal #{journal}, month #{month}, year #{year} could not be saved",
             :status => 500,
             :source_id => id)
        journals_with_errors << journal
      end
    end
    journals_with_errors
  end

  # Parse usage stats and store in CouchDB
  def parse_feed(month, year, options={})

    journals_array = journals.split(",")
    journals_with_errors = []
    journals_array.each do |journal|
      filename = "pmcstat_#{journal}_#{month}_#{year}.xml"
      file = File.open("#{Rails.root}/data/#{filename}", 'r') { |f| f.read }
      document = Nokogiri::XML(file)

      status = document.at_xpath("//pmc-web-stat/response/@status").value
      if (status != "0")
        error_message = document.at_xpath("//pmc-web-stat/response/error").content
        Alert.create(:exception => "", :class_name => "Net::HTTPInternalServerError",
                     :message => "PMC Usage stats for journal #{journal}, month #{month} and year #{year}: #{error_message}",
                     :status => 500,
                     :source_id => id)
        journals_with_errors << journal
      else
        # go through all the articles in the xml document
        document.xpath("//article").each do |article|
          article = article.to_hash
          article = article["article"]

          doi = article["meta-data"]["doi"]

          view = article["usage"]
          view['year'] = year.to_s
          view['month'] = month.to_s

          # try to get the existing information about the given article
          data = get_json("#{url}#{CGI.escape(doi)}")

          if (data['views'].nil?)
            data = { 'views' => [view] }
          else
            # update existing entry
            data['views'].delete_if { |view| view['month'] == month.to_s && view['year'] == year.to_s }
            data['views'] << view
          end

          put_alm_data("#{url}#{CGI.escape(doi)}", { :data => data })
        end
      end
    end
    journals_with_errors
  end

  def get_data(article, options={})

    # Check that article has DOI and is at least one day old
    return { :events => [], :event_count => nil } if (article.doi.blank? || Time.zone.now - article.published_on.to_time < 1.day)

    query_url = get_query_url(article)
    result = get_json(query_url, options)

    return nil if result.nil? || !result['views']

    events = result["views"]

    pdf = events.nil? ? 0 : events.inject(0) { |sum, hash| sum + hash["pdf"].to_i }
    html = events.nil? ? 0 : events.inject(0) { |sum, hash| sum + hash["full-text"].to_i }
    event_count = pdf + html

    event_metrics = { :pdf => pdf,
                      :html => html,
                      :shares => nil,
                      :groups => nil,
                      :comments => nil,
                      :likes => nil,
                      :citations => nil,
                      :total => event_count }

    { :events => events,
      :event_count => event_count,
      :event_metrics => event_metrics }
  end

  def get_query_url(article)
    "#{url}#{article.doi_escaped}"
  end

  def get_feed_url(month, year, journal)
    "http://www.pubmedcentral.nih.gov/utils/publisher/pmcstat/pmcstat.cgi?year=#{year}&month=#{month}&jrid=#{journal}&user=#{username}&password=#{password}"
  end

  def get_config_fields
    [{:field_name => "url", :field_type => "text_area", :size => "90x2"},
     {:field_name => "journals", :field_type => "text_area", :size => "90x2"},
     {:field_name => "username", :field_type => "text_field"},
     {:field_name => "password", :field_type => "password_field"}]
  end

  def url
    config.url
  end

  def url=(value)
    # make sure we have trailing slash
    config.url = value ? value.chomp("/") + "/" : nil
  end

  def journals
    config.journals
  end

  def journals=(value)
    config.journals = value
  end

end