class IpWhiteListsController < AdminController
  before_action :set_ip_white_list, only: %i[ show edit update destroy ]

  # GET /ip_white_lists or /ip_white_lists.json
  def index
    @ip_white_lists = IpWhiteList.all
  end

  # GET /ip_white_lists/1 or /ip_white_lists/1.json
  def show
  end

  # GET /ip_white_lists/new
  def new
    @ip_white_list = IpWhiteList.new
  end

  # GET /ip_white_lists/1/edit
  def edit
  end

  # POST /ip_white_lists or /ip_white_lists.json
  def create
    @ip_white_list = IpWhiteList.new(ip_white_list_params)

    respond_to do |format|
      if @ip_white_list.save
        format.html { redirect_to ip_white_list_url(@ip_white_list), notice: "Ip white list was successfully created." }
        format.json { render :show, status: :created, location: @ip_white_list }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @ip_white_list.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ip_white_lists/1 or /ip_white_lists/1.json
  def update
    respond_to do |format|
      if @ip_white_list.update(ip_white_list_params)
        format.html { redirect_to ip_white_list_url(@ip_white_list), notice: "Ip white list was successfully updated." }
        format.json { render :show, status: :ok, location: @ip_white_list }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @ip_white_list.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ip_white_lists/1 or /ip_white_lists/1.json
  def destroy
    @ip_white_list.destroy

    respond_to do |format|
      format.html { redirect_to ip_white_lists_url, notice: "Ip white list was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ip_white_list
      @ip_white_list = IpWhiteList.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def ip_white_list_params
      params.require(:ip_white_list).permit(:ip, :expired_at, :memo)
    end
end
