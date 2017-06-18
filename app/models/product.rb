class Product < ApplicationRecord
  has_many :reviews

  validates :asin, presence: true, uniqueness: true

  def build_from_xml(xml)
    hash = Hash.from_xml(xml)
    item_data = hash['html']['body']['itemlookupresponse']['items']['item']
    self.asin = item_data['asin']
    self.title = item_data['itemattributes']['title']
    self.review_url = item_data['customerreviews']['iframeurl']
  end

  def load_reviews_and_rating
    if self.review_valid_until.nil? || Time.now >= self.review_valid_until
      page = AmazonApi.load_from_url(self.review_url)
      review_img = page.css('.asinReviewsSummary img').first
      self.rating = review_img.nil? ? 0 : review_img.attributes['title'].value
      reviews = Array.new
      page.css('.reviewText').each do |content|
        review = Review.new
        review.review = content.text
        previous = content
        (0..3).each do |i|
          previous = previous.previous_element
          if i == 2
            review.reviewer = previous.search('span').first.text
          end
        end
        review.title = previous.search('b').first.text.strip
        review.date = Date.parse(previous.search('nobr').first.text)
        review.rating = previous.search('img').first.attributes['title'].value.split(" ")[0]
        reviews << review
      end
      self.review_valid_until = Time.now + 24.hours
      self.reviews = reviews
    end
  end

end
