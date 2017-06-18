class Product < ApplicationRecord
  has_many :reviews

  validates :asin, presence: true, uniqueness: true

  def self.build_from_xml(xml)
    hash = Hash.from_xml(xml)
    item_data = hash['html']['body']['itemlookupresponse']['items']['item']
    product = Product.new
    product.asin = item_data['asin']
    product.title = item_data['itemattributes']['title']
    product.review_url = product.title = item_data['customerreviews']['iframeurl']
    product.review_valid_until = Time.now + 24.hours
    # page = AmazonApi.load_from_url(product.review_url)
    # product.rating = load_reviews_and_rating(product.review_url)
    # load_reviews(product.review_url)
    # product.save!
    product
  end

  def load_reviews_and_rating
    # byebug
    # Nokogiri::HTML(open(self.review_url))
    page = AmazonApi.load_from_url(self.review_url)

    reviews = Array.new
    # Finds the texts of all reviews in the page, these are the only elements that have something identifiable
    page.css('.reviewText').each do |content|
      # byebug
      review = Review.new
      review.review = content.text
      previous = content
      (0..3).each do |i|
        previous = previous.previous_element
        if i == 2
          # byebug
          review.reviewer = previous.search('span').first.text
        end
      end
      # byebug
      review.title = previous.search('b').first.text.strip
      review.date = Date.parse(previous.search('nobr').first.text)
      # byebug
      review.rating = previous.search('img').first.attributes['title'].value.split(" ")[0]
      reviews << review
    end
    self.reviews = reviews
    # previous = page.css('.reviewText')[0]
    # (0..3).each do |i|
    #   previous = previous.previous_element
    # end
    # byebug
    # f.title = previous.text.strip
    # f.title = page.css('.reviewText')[0].previous_element.previous_element.previous_element.previous_element.children[3].children[0].text
    # Finds rating scrapping the page
    # byebug
    # page.css('.asinReviewsSummary')[0].children[1].children[0].attributes['title'].value.split(" ")[0]
    # self.update
    # byebug
    # a = "5"
  end

end
