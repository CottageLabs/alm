xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title CONFIG[:useragent] + ": most-cited articles in #{@source.display_name}"
    xml.link source_url(@source)

    @retrieval_statuses.each do |retrieval_status|
      xml.item do
        xml.title retrieval_status.article.title
        xml.description pluralize(retrieval_status.event_count, "#{@source.display_name} event")
        xml.pubDate retrieval_status.article.published_on.to_time.utc.to_s(:rfc822)
        xml.link retrieval_status.article.doi_as_url
        xml.guid retrieval_status.article.uid
      end
    end
  end
end
