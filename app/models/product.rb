class Product < ApplicationRecord
  has_many :reviews

  validates :asin, presence: true, uniqueness: true

  def build_from_xml(xml)
    hash = Hash.from_xml(xml)
    item_data = hash['html']['body']['itemlookupresponse']['items']['item']
    self.asin = item_data['asin']
    self.title = item_data['itemattributes']['title']
    self.review_url = item_data['customerreviews']['iframeurl']
    self.image_url = item_data['mediumimage']['url']
  end

  def load_reviews_and_rating
    if self.review_valid_until.nil? || Time.now >= self.review_valid_until
      page = AmazonApi.load_from_url(self.review_url)
      review_img = page.css('.asinReviewsSummary img').first
      self.rating = review_img.nil? ? 0 : review_img.attributes['title'].value
      reviews = Array.new
      reviewers = Array.new
    
      if reviews.length < 3
        pending_reviews = page.css('.crIFrameReviewList').search('table > tr > td > div')
        
        (0..(pending_reviews.length-1)).each do |i|
          css_text = pending_reviews[i].search('.reviewText').text
          text = ''
          if css_text.length == 0
            text = clean_text(pending_reviews[i].text)
          end
          if css_text.length > 0 || text.length > 0
            # Prevent duplicated reviews
            if !reviewers.include? pending_reviews.search('div>div>div>a>span').first.text
              review = Review.new
              review.date = Date.parse(pending_reviews.search('div>nobr').first.text)
              review.title = pending_reviews.search('div>b').first.text
              review.reviewer = pending_reviews.search('div>div>div>a>span').first.text
              review.rating = pending_reviews.search('img').first.attributes['title'].value.split(" ")[0]
              pending_reviews[i].search('div').remove

              review.review = css_text.length > 0 ? css_text : clean_text(pending_reviews[i].text)
              reviews << review
            end
          end
        end
      end
      self.review_valid_until = Time.now + 24.hours
      self.reviews = reviews
    end
  end

  private
  def clean_text(text)
    text.gsub!("\n", "").gsub!("...Read more", "").strip
  end
end