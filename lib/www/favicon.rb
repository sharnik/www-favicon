require 'rubygems'
require 'open-uri'
require 'net/https'
require 'hpricot'

module WWW
  class Favicon
    VERSION = '0.0.6'

    def find(url)
      response = open(url)
      find_from_html(response.read, response.base_uri.to_s)
    end

    def find_from_html(html, url)
      find_from_link(html, url) || default_path(url)
    end

    def valid_favicon_url?(url)
      begin
        response = open(url)
      rescue OpenURI::HTTPError
        return false
      end
      (
        response.status[0] =~ /\A2/ &&
        response.read != ''
      ) ? true : false
    end

    private

    def find_from_link(html, url)
      doc = Hpricot(html)

      doc.search('//link').each do |link|
        if link[:rel] =~ /^(shortcut )?icon$/i
          favicon_url_or_path = link[:href]

          if favicon_url_or_path =~ /^http/
            return favicon_url_or_path
          else
            return URI.join(url, favicon_url_or_path).to_s
          end
        end
      end

      nil
    end

    def default_path(url)
      %w(ico png gif jpg jpeg).each do |extension|
        uri = URI(url)
        uri.path = "/favicon.#{extension}"
        %w[query fragment].each do |element|
          uri.send element + '=', nil
        end
        return uri.to_s if valid_favicon_url?(uri.to_s)
      end
      nil
    end
  
  end
end
