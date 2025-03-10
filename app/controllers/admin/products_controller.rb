class Admin::ProductsController < AdminController
  before_action :set_admin_product, only: %i[ show edit update destroy ]

  # GET /admin/products or /admin/products.json
  def index
    if params[:query].present?
       @pagy, @admin_products = pagy(Product.where("name ILIKE ? OR item_number LIKE ?", "%#{params[:query]}%", "%#{params[:query]}%"))
    else
      @pagy, @admin_products = pagy(Product.all)
    end
  end

  # GET /admin/products/1 or /admin/products/1.json
  def show
  end

  # GET /admin/products/new
  def new
    @admin_product = Product.new
  end

  # GET /admin/products/1/edit
  def edit
  end

  # POST /admin/products or /admin/products.json
  def create
    @admin_product = Product.new(admin_product_params)

    respond_to do |format|
      if @admin_product.save
        format.html { redirect_to admin_product_url(@admin_product), notice: "Product was successfully created." }
        format.json { render :show, status: :created, location: @admin_product }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @admin_product.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/products/1 or /admin/products/1.json
  def update
    @admin_product = Product.find(params[:id])
    if @admin_product.update(admin_product_params.reject { |k| k["images"] })
      if admin_product_params["images"]
        admin_product_params["images"].each do |image|
          @admin_product.images.attach(image)
        end
      end
      redirect_to admin_products_path, notice: "Product was successfully updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end


  # DELETE /admin/products/1 or /admin/products/1.json
  def destroy
    @admin_product.destroy!

    respond_to do |format|
      format.html { redirect_to admin_products_path, status: :see_other, notice: "Product was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def import
    Rails.logger.info "Admin::ProductsController::Import"
    return redirect_to request.referer, notice: 'No file added' if params[:file].nil?
    content_type = params[:file].content_type 
    return redirect_to request.referer, notice: 'Only CSV or zip files allowed' unless ['text/csv', 'application/zip', 'application/x-zip-compressed'].include?(content_type)

    category_id = 1
    CsvImportService.new.import_products(content_type, params[:file], category_id)

    redirect_to request.referer, notice: 'Import started...'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_admin_product
      @admin_product = Product.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def admin_product_params
      params.require(:product).permit(:name, :description, :price, :category_id, :active, images: [])
    end
end
