
class Api::V1::ProductsController < Api::V1::BaseController

  before_action :set_tag, only: [:load_product]

  # Loads all products from the database
  # TODO:d pagination
  def index
    render status: :ok, json: Product.all
  end

  # Updates the product based on the asin received
  def update
    amazon = AmazonApi.new
    url = amazon.fetch_product(params[:asin])
    dom = AmazonApi.load_from_url(url)
    product = Product.build_from_xml(dom.to_xml)
    # byebug
    # product.save!
    product.load_reviews_and_rating
    # render :json => product, :include => {:reviews => {}}
    # render status: :ok, json: product.to_json
    render status: :ok, json: product, include: :reviews
  rescue StandardError => e
     render status: 404, json: {erro: e.message}
  end

  def show

  end


  private
  def set_product
    @product = Product.find_by(asin: params[:asin])
  end

  def product_params
    params.require(:product).permit(:asin)
  end
end
