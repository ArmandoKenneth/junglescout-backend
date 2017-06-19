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
    byebug
    if self.review_valid_until.nil? || Time.now >= self.review_valid_until
      page = AmazonApi.load_from_url(self.review_url)
      review_img = page.css('.asinReviewsSummary img').first
      self.rating = review_img.nil? ? 0 : review_img.attributes['title'].value
      reviews = Array.new
      # Only works if reviews do not have the read more option
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
      # Reviews may have the read more option. In that case, search again, because the HTML structure
      # is different
      if reviews.length < 3
        pending_reviews = page.css('.crIFrameReviewList').search('table > tr > td > div')
        page.css('.crIFrameReviewList').search('table > tr > td > div > div').remove

        (0..(pending_reviews.length-1)).each do |i|
          # byebug
          text = clean_text(page.css('.crIFrameReviewList').search('table > tr > td > div')[i].text)
          # byebug
          if text.length > 0
            review = Review.new
            review.title = i
            review.review = text
            reviews << review
          end
        end
      end
      # byebug
      self.review_valid_until = Time.now + 24.hours
      self.reviews = reviews
      # self.reviews
    end
  end

  private
  def clean_text(text)
    text.gsub!("\n", "").strip
  end

end

# title from review
# page.css('.crIFrameReviewList').search('table').children.search('div b').first.children.first.text

# date
# page.css('.crIFrameReviewList').search('table').children.search('div nobr').first.children.first.text

# rating from review
# page.css('.crIFrameReviewList').search('table').children.search('div span img').first.attributes['title'].value

# Reviewer
# page.css('.crIFrameReviewList').search('table').children.search('div a').children.first.text ou div div div a

# Review
# remove all tiny
# page.css('.crIFrameReviewList').search('table').children.search('div//.tiny').remove
# remove all div
# page.css('.crIFrameReviewList').search('table').children.search('div//div').remove
# get review
# page.css('.crIFrameReviewList').search('table').children.search('div').text

# page.css('.crIFrameReviewList').search('table > tr > td > div').length
# page.css('.crIFrameReviewList').search('table > tr > td > div > div').remove

