require 'time'
require 'uri'
require 'openssl'
require 'base64'
require 'open-uri'
require 'nokogiri'

class AmazonApi

  # Your AWS Access Key ID, as taken from the AWS Your Account page
  AWS_ACCESS_KEY_ID = "AKIAJR6QSGIAZERIBYRQ"

  # Your AWS Secret Key corresponding to the above ID, as taken from the AWS Your Account page
  AWS_SECRET_KEY = "U8ADyZoTBfi3KNtkUZ6ZJQjx0rflQJWrb9MKPt1o"

  # The region you are interested in
  ENDPOINT = "webservices.amazon.com"

  REQUEST_URI = "/onca/xml"


  def build_url(params)
    params["Timestamp"] = Time.now.gmtime.iso8601 if !params.key?("Timestamp")
    canonical_query_string = params.sort.collect do |key, value|
      [URI.escape(key.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")), URI.escape(value.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))].join('=')
    end.join('&')
    string_to_sign = "GET\n#{ENDPOINT}\n#{REQUEST_URI}\n#{canonical_query_string}"
    signature = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), AWS_SECRET_KEY, string_to_sign)).strip()
    request_url = "http://#{ENDPOINT}#{REQUEST_URI}?#{canonical_query_string}&Signature=#{URI.escape(signature, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))}"
    request_url
  end

  def fetch_product(asin)
    params = {
      "Service" => "AWSECommerceService",
      "Operation" => "ItemLookup",
      "AWSAccessKeyId" => ENV['AMAZON_ACCESS_KEY'],
      "AssociateTag" => ENV['AMAZON_ASSOCIATE_ID'],
      "ItemId" => "B002QYW8LW",
      "IdType" => "ASIN",
      "ResponseGroup" => "Images,ItemAttributes,Reviews"
    }
    build_url(params)
  end

  def self.load_from_url(url)
    Nokogiri::HTML(open(url))
  end


end 