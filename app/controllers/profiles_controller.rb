class ProfilesController < ApplicationController
  before_action only: [:edit, :update, :destroy] do
    redirect_to login_path unless current_user
  end

  def show
    @user = User.includes(:collections).where(linked_id: nil).find_by("upper(username) = ?", params[:username].upcase)

    if @user.present?
      if @user.verified? && @user.nice_url.present? && @user.nice_url != @user.username
        redirect_to profile_path(@user.nice_url)
      end
    else
      @user = User.where(verified: true).find_by("upper(nice_url) = ?", params[:username].upcase)
    end

    not_found unless @user.present?

    @posts = @user.posts.select_overview_columns.public?.order("#{ allowed_sort_params.include?(params[:sort_posts]) ? params[:sort_posts] : "created_at" } DESC").page(params[:page])
    @blocks = Block.where(user_id: @user.id, content_type: :profile).order(position: :asc, created_at: :asc)

    respond_to do |format|
      format.html
      format.js { render "posts/infinite_scroll_posts" }
      format.json {
        set_request_headers
        render json: @posts
      }
    end
  end

  def edit
    @user = current_user
    @blocks = Block.where(user_id: @user.id, content_type: :profile).order(position: :asc, created_at: :asc)

    redirect_to root_path unless @user
  end

  def update
    @user = current_user

    if profile_params[:featured_posts] == nil
      @user.featured_posts = ""
    end

    respond_to do |format|
      if @user.update(profile_params)
        format.html {
          flash[:alert] = "Successfully saved"
          redirect_to edit_profile_path
        }
        format.js { render "application/success" }
      else
        format.js { render "application/error" }
      end
    end
  end

  private

  def profile_params
    params.require(:user).permit(:profile_image, :banner_image, :link, :description, :custom_css, { featured_posts: [] })
  end

  def not_found
    raise ActionController::RoutingError.new("Not Found")
  end

  def allowed_sort_params
    %w[updated_at created_at hotness favorites_count]
  end
end
