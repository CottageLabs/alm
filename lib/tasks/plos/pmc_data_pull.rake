# $HeadURL$
# $Id$
#
# Copyright (c) 2009-2011 by Public Library of Science, a non-profit corporation
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

require "source_helper"

include SourceHelper

namespace :pmc do

  task :update => :environment do
    
    # looking at last month's information
    if ENV["MONTH"] && ENV["YEAR"]
      month = ENV["MONTH"]
      year = ENV["YEAR"]
    else
      time = Time.new
      month = time.month - 1
      year = time.year
    end

    Rails.logger.info "Getting PMC information for #{month} #{year}"
    
    source = Source.find_by_type("Pmc")
    config = YAML.parse(source.misc)
    filepath = config["filepath"]
    filepath = filepath.transform

    mainDocument = XML::Document.new()
    mainDocument.root = XML::Node.new('articles')
    mainDocument.root.attributes['month'] = month.to_s
    mainDocument.root.attributes['year'] = year.to_s

    journals = ["plosbiol", "plosmed", "ploscomp", "plosgen", "plospath", "plosone", "plosntd"];

    journals.each do |journal|
      Rails.logger.info "Getting PMC information for journal #{journal}"

      url = "http://www.pubmedcentral.nih.gov/utils/publisher/pmcstat/pmcstat.cgi?year=#{year}&month=#{month}&jrid=#{journal}&user=plospubs&password=er56nm"
      
      get_xml(url) do |document|
        document.find("/pmc-web-stat/response").each do | response |
          attributes = response.attributes
          if (attributes['status'] <=> "0")
            # good
            document.find("//article").each do |article|
              article2 = mainDocument.import(article)
              mainDocument.root << article2
            end
          else
            # bad
            Rails.logger.error "Bad status from PMC"
          end
        end
      end
    end

    mainDocument.save(filepath)

    # keep a history of the files
    index = filepath.rindex('.')
    filepath = filepath[0..index-1] + "_#{month}_#{year}.xml"
    mainDocument.save(filepath)

  end

  task :update_all => :environment do
    # this code is meant to run just once, when PMC is added as a source
    # should be removed after the deployment.

    # get all the data
    months = (1..12).to_a
    year = 2010
        
    months.each do | month |
      call_rake "pmc:update", {:MONTH => month, :YEAR => year}
    end

    time = Time.new
    months = (1..time.month-1).to_a
    year = 2011

    months.each do | month |
      call_rake "pmc:update", {:MONTH => month, :YEAR => year}
    end
  end

  # this is only used by update_all task, remove it when we remove update_all task
  def call_rake(task, options = {})
    options[:rails_env] ||= Rails.env
    args = options.map { |n, v| "#{n.to_s.upcase}='#{v}'" }
    system "rake #{task} #{args.join(' ')} --trace"
  end

  task :update_all2 => :environment do
    # this code is meant to run just once, when PMC is added as a source
    # should be removed after the deployment.

    puts Time.now
    
    # there should be just one
    source = Source.find_by_type("Pmc")

    retriever = Retriever.new(:lazy => 0,
      :only_source => "Pmc",
      :raise_on_error => ENV["RAISE_ON_ERROR"])

    config = YAML.parse(source.misc)
    filepath = config["filepath"]
    filepath = filepath.transform
    index = filepath.rindex('.')

    years = [2010, 2011]
    
    years.each do | year |
      if (year == 2010)
        months = (1..12).to_a
      end

      if (year == 2011)
        time = Time.new
        months = (1..time.month-1).to_a
      end

      months.each do | month |
        puts "#{month} / #{year}"

        month_filepath = filepath[0..index-1] + "_#{month}_#{year}.xml"
        system "cp #{month_filepath} #{filepath}"

        puts "#{month_filepath} #{filepath}"

        parser = XML::Parser.file(filepath)
        document = parser.parse

        nodes = document.find("//article")
        total = nodes.count

        puts "total #{total}"

        i = 1;
        nodes.each do | article_document |
          metadata = article_document.find_first("meta-data")
          attributes = metadata.attributes
          doi = attributes[:doi]

          puts "#{month}/#{year} #{i} of #{total} #{doi}"
          i = i + 1

          article = Article.find_by_doi(doi)
          if article != nil
            retrieval = Retrieval.find_or_create_by_article_id_and_source_id(article.id, source.id)
            retriever.update_one(retrieval, source, article)
          else
            puts "article #{doi} doesn't exist"
          end

        end # article
      end  # month
    end  # year

    puts Time.now
  end
  
end
