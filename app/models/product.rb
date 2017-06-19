class Product < ApplicationRecord
  has_many :reviews

  validates :asin, presence: true, uniqueness: true

  def build_from_xml(xml)
    hash = Hash.from_xml(xml)
    item_data = hash['html']['body']['itemlookupresponse']['items']['item']
    # byebug
    self.asin = item_data['asin']
    self.title = item_data['itemattributes']['title']
    self.review_url = item_data['customerreviews']['iframeurl']
    self.image_url = item_data['mediumimage']['url']
  end

  def load_reviews_and_rating
    # byebug
    if self.review_valid_until.nil? || Time.now >= self.review_valid_until
      page = AmazonApi.load_from_url(self.review_url)
      review_img = page.css('.asinReviewsSummary img').first
      self.rating = review_img.nil? ? 0 : review_img.attributes['title'].value
      reviews = Array.new
      # Only works if reviews do not have the read more option
      reviewers = Array.new
      # page.css('.reviewText').each do |content|
      #   review = Review.new
      #   review.review = content.text
      #   previous = content
      #   (0..3).each do |i|
      #     previous = previous.previous_element
      #     if i == 2
      #       review.reviewer = previous.search('span').first.text
      #       reviewers << review.reviewer
      #     end
      #   end
      #   review.title = previous.search('b').first.text.strip
      #   review.date = Date.parse(previous.search('nobr').first.text)
      #   review.rating = previous.search('img').first.attributes['title'].value.split(" ")[0]
      #   reviews << review
      # end
      # Reviews may have the read more option. In that case, search again, because the HTML structure
      # is different
      if reviews.length < 3
        pending_reviews = page.css('.crIFrameReviewList').search('table > tr > td > div')
        
        (0..(pending_reviews.length-1)).each do |i|
          # byebug
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
              # byebug
              review.rating = pending_reviews.search('img').first.attributes['title'].value.split(" ")[0]
              pending_reviews[i].search('div').remove
              # text = pending_reviews[i].search('.reviewText').text
              # if text.length == 0
              #   text = clean_text(pending_reviews[i].text)
              # end
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