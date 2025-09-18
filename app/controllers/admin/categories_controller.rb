class Admin::CategoriesController < AdminController
  before_action :set_admin_category, only: %i[ show edit update destroy ]

  # GET /admin/categories or /admin/categories.json
  def index
    @admin_categories = Category.all
  end

  # GET /admin/categories/1 or /admin/categories/1.json
  def show
  end

  # GET /admin/categories/new
  def new
    @admin_category = Category.new
  end

  # GET /admin/categories/1/edit
  def edit
  end

  # POST /admin/categories or /admin/categories.json
  def create
    @admin_category = Category.new(admin_category_params)

    respond_to do |format|
      if @admin_category.save
        format.html { redirect_to admin_category_url(@admin_category), notice: "Category was successfully created." }
        format.json { render :show, status: :created, location: @admin_category }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @admin_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/categories/1 or /admin/categories/1.json
  def update
    respond_to do |format|
      if @admin_category.update(admin_category_params)
        format.html { redirect_to admin_category_url(@admin_category), notice: "Category was successfully updated." }
        format.json { render :show, status: :ok, location: @admin_category }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @admin_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/categories/1 or /admin/categories/1.json
  def destroy
    @admin_category.destroy!

    respond_to do |format|
      format.html { redirect_to admin_categories_url, status: :see_other, notice: "Category was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  # import products into this category
  def import_products
    Rails.logger.info "Admin::CategoriesController::ImportProducts"
    return redirect_to request.referer, notice: "No file added" if params[:file].nil?
    content_type = params[:file].content_type
    return redirect_to request.referer, notice: "Only CSV or zip files allowed" unless [ "text/csv", "application/zip", "application/x-zip-compressed" ].include?(content_type)

    category_id = params[:category_id].to_i
    CsvImportService.new.import_products(content_type, params[:file], category_id)

    redirect_to request.referer, notice: "Import started..."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_admin_category
      @admin_category = Category.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def admin_category_params
      params.require(:category).permit(:name, :description, :image)
    end
end
