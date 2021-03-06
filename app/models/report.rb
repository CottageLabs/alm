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

require 'csv'
require 'zip'

class Report < ActiveRecord::Base

  has_and_belongs_to_many :users

  serialize :config, OpenStruct

  def self.available(role)
    if role == "user"
      where(:private => false)
    else
      all
    end
  end

  # Generate CSV with event counts for all articles and installed sources
  def self.to_csv(options = {})

    if options[:include_private_sources]
      sources = Source.installed
    else
      sources = Source.installed.where(:private => false)
    end

    sql_stat = "SELECT a.doi, a.published_on, a.title"
    sources.each do |source|
      sql_stat = sql_stat + ", GROUP_CONCAT(IF(rs.source_id = #{source.id}, CAST(rs.event_count as CHAR), NULL)) AS '#{source.name}'"
    end
    sql_stat = sql_stat + " FROM retrieval_statuses rs, articles a WHERE a.id = rs.article_id GROUP BY rs.article_id"

    results = connection.execute sql_stat

    CSV.generate do |csv|
      csv << ["doi", "publication_date", "title"] + sources.map(&:name)
      results.each { |row| csv << row }
    end
  end

  # write report into folder with current date in name
  def self.write(filename, content, options = {})
    return nil unless filename && content

    date = options[:date] || Date.today.iso8601
    folderpath = "#{Rails.root}/data/report_#{date}"
    Dir.mkdir folderpath unless Dir.exist? folderpath
    filepath = "#{folderpath}/#{filename}"
    if IO.write(filepath, content)
      filepath
    else
      nil
    end
  end

  def self.read_stats(stat, options = {})
    date = options[:date] || Date.today.iso8601
    filename = "#{stat[:name]}.csv"
    filepath = "#{Rails.root}/data/report_#{date}/#{filename}"
    csv = File.exist?(filepath) ? CSV.read(filepath, { headers: stat[:headers] ? stat[:headers] : :first_row, return_headers: true }) : nil
  end

  def self.merge_stats(options = {})
    if options[:include_private_sources]
      alm_stats = self.read_stats({ name: "alm_private_stats" })
    else
      alm_stats = self.read_stats({ name: "alm_stats" })
    end
    return nil if alm_stats.blank?

    stats = [{ name: "mendeley_stats", headers: ["doi","mendeley_readers","mendeley_groups","mendeley"] },
             { name: "pmc_stats", headers: ["doi","pmc_html","pmc_pdf","pmc"] },
             { name: "counter_stats", headers: ["doi","counter_html","counter_pdf","counter"] }]
    stats.each do |stat|
      stat[:csv] = self.read_stats(stat, options).to_a
      alm_stats.delete(stat[:name]) unless stat[:csv].blank?
    end

    # return alm_stats if no additional stats are found
    stats.reject! { |stat| stat[:csv].blank? }
    return alm_stats if stats.empty?

    CSV.generate do |csv|
      alm_stats.each do |row|
        stats.each do |stat|
          # find row based on DOI, and discard the first item (the doi). Otherwise pad with zeros
          match = stat[:csv].assoc(row.field("doi"))
          match = match.present? ? match[1..-1] : [0,0,0]
          row.push(*match)
        end
        csv << row
      end
    end
  end

  def self.zip_file(options = {})
    date = options[:date] || Date.today.iso8601
    filename = "alm_report_#{date}.csv"
    filepath = "#{Rails.root}/data/report_#{date}/alm_report.csv"
    zip_filepath = "#{Rails.root}/public/files/alm_report.zip"
    return nil unless File.exist? filepath

    Zip::File.open(zip_filepath, Zip::File::CREATE) do |zipfile|
      zipfile.add(filename, filepath)
    end
    File.chmod(0755, zip_filepath)
    zip_filepath
  end

  def self.zip_folder(options = {})
    date = options[:date] || Date.today.iso8601
    folderpath = "#{Rails.root}/data/report_#{date}"
    zip_filepath = "#{Rails.root}/data/report_#{date}.zip"
    return nil unless File.exist? folderpath

    Zip::File.open(zip_filepath, Zip::File::CREATE) do |zipfile|
      Dir["#{folderpath}/*"].each do |filepath|
        zipfile.add(File.basename(filepath), filepath)
      end
    end
    FileUtils.rm_rf(folderpath)
    zip_filepath
  end

  def interval
    config.interval || 1.day
  end

  def interval=(value)
    config.interval = value
  end

  # Reports are sent via delayed_job

  def send_error_report
    ReportMailer.delay(queue: 'mailer', priority: 3).send_error_report(self)
  end

  def send_status_report
    ReportMailer.delay(queue: 'mailer', priority: 3).send_status_report(self)
  end

  def send_article_statistics_report
    ReportMailer.delay(queue: 'mailer', priority: 3).send_article_statistics_report(self)
  end

  def send_disabled_source_report(source_id)
    ReportMailer.delay(queue: 'mailer', priority: 1).send_disabled_source_report(self, source_id)
  end

end