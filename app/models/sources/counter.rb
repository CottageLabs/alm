class Counter < Source
  include Log
  include SourceHelper
  attr_accessor :verbose
  
  def uses_url; true; end
 
  def query(article, options={})
    raise(ArgumentError, "Counter configuration requires url") \
      if url.blank?
    
    doi = parseDOI(article.doi)

    furl = "#{url}#{CGI.escape(doi)}"
     
    log_info("Counter query: #{furl}")
    
    get_xml(furl, options) do |document|
      views = []
      
      document.find("//rest/response/results/item").each do | view |

        month = view.find_first("month")
        year = view.find_first("year")
        month = view.find_first("month")
        html = view.find_first("get-document")
        xml = view.find_first("get-xml")
        pdf = view.find_first("get-pdf")

        curMonth = {}
        curMonth[:month] = month.content
        curMonth[:year] = year.content
        
        if(pdf) 
          curMonth[:pdf_views] = pdf.content 
        else
          curMonth[:pdf_views] = 0
        end
        
        if(xml)
          curMonth[:xml_views] = xml.content
        else 
          curMonth[:xml_views] = 0
        end
        
        if(html)
          curMonth[:html_views] = html.content
        else 
          curMonth[:html_views] = 0
        end
        
        views << curMonth
      end
      
      citations = []
      
      if(views.size > 0)
        citation = {}
        citation[:uri] = "#{url}#{CGI.escape(doi)}"
        citation[:views] = views;
        
        citations << citation
      end
      
      citations
    end
  end
  
  def parseDOI(doi)
    #The Drupal API expexts the article DOI in an alternate format
    #here I do some processing on it
    #Start:10.1371/journal.pone.0003431
    #end:10.1371/pone.0003431
    doiParts = doi.split(/\.|\//)
    "#{doiParts[3]}.#{doiParts[4]}"
  end

  def citations_to_csv(csv, retrieval)
    
    csv << [ "uri", "year", "month", "get-document", "get-pdf", "get-xml" ]    
    
    retrieval.citations.each do |citation|
      if(citation.details != nil)
        uri = citation.details.fetch(:uri)
        views = citation.details.fetch(:views)
        
         views.each { | month |
          csv << [ uri, month.fetch(:year), month.fetch(:month), month.fetch(:html_views), month.fetch(:pdf_views), month.fetch(:xml_views) ]
        }
      end  
    end
  end
  
  def public_url(retrieval)
    doi = parseDOI(retrieval.article.doi)

   "#{url}#{CGI.escape(doi)}"
  end
end
