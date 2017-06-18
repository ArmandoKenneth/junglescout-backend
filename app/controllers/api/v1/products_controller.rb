
class Api::V1::ProductsController < Api::V1::BaseController

  before_action :set_product, only: [:show, :update]

  # Loads all products from the database
  # TODO: add pagination
  def index
    render status: :ok, json: Product.all
  end

  def update
    if @product.nil?
      @product = Product.new
    end
    url = AmazonApi.build_fetch_product_url(params[:asin])
    dom = AmazonApi.load_from_url(url)
    @product.build_from_xml(dom.to_xml)
    @product.load_reviews_and_rating
    @product.save!
    render status: :ok, json: @product, include: :reviews
  rescue StandardError => e
     render status: :bad_request, json: {erro: e.message}
  end

  def show
    render status: :bad_request, json: {error: "No product with the given ASIN was found"} and return if @product.nil?
    render status: :ok, json: @product, include: :reviews
  end

  private
  def set_product
    @product = Product.find_by(asin: params[:asin])
  end

  def product_params
    params.permit(:asin)
  end
end
