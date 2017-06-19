require 'time'
require 'uri'
require 'openssl'
require 'base64'
require 'open-uri'
require 'nokogiri'

class AmazonApi

  # The region you are interested in
  ENDPOINT = "webservices.amazon.com"

  REQUEST_URI = "/onca/xml"

  # Default from Amazon API documentation
  def self.build_url(params)
    params["Timestamp"] = Time.now.gmtime.iso8601 if !params.key?("Timestamp")
    canonical_query_string = params.sort.collect do |key, value|
      [URI.escape(key.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")), URI.escape(value.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))].join('=')
    end.join('&')
    string_to_sign = "GET\n#{ENDPOINT}\n#{REQUEST_URI}\n#{canonical_query_string}"
    signature = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), ENV['AMAZON_SECRET_KEY'], string_to_sign)).strip()
    "http://#{ENDPOINT}#{REQUEST_URI}?#{canonical_query_string}&Signature=#{URI.escape(signature, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))}"
  end

  def self.build_fetch_product_url(asin)
    params = {
      "Service" => "AWSECommerceService",
      "Operation" => "ItemLookup",
      "AWSAccessKeyId" => ENV['AMAZON_ACCESS_KEY'],
      "AssociateTag" => ENV['AMAZON_ASSOCIATE_ID'],
      "ItemId" => asin,
      "IdType" => "ASIN",
      "ResponseGroup" => "Images,ItemAttributes,Reviews"
    }
    self.build_url(params)
  end

  def self.load_from_url(url)
    user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_0) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.854.0 Safari/535.2"
    Nokogiri::HTML(open(url, 'User-Agent' => user_agent, 'read_timeout' => '10' ), nil, "UTF-8")
  end


end 