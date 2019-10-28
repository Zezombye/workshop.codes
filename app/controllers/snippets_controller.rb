class SnippetsController < ApplicationController
  before_action :set_snippet, only: [:show, :edit, :update, :destroy]

  before_action only: [:edit, :update, :destroy] do
    redirect_to root_path unless current_user && current_user == @snippet.user
  end

  before_action only: [:create, :new] do
    redirect_to root_path unless current_user
  end

  def index
    @snippets = Snippet.where(private: 0).order(created_at: :desc).page params[:page]
  end

  def search
    @snippets = Snippet.where(private: 0).search(params[:search]).records.page params[:page]
  end

  def show
    if @snippet.user != current_user && @snippet.private?
      not_found
    end
  end

  def new
    @snippet = Snippet.new
  end

  def edit
  end

  def create
    @snippet = Snippet.new(snippet_params)
    @snippet.unique_id = SecureRandom.base64(8)
    @snippet.user_id = current_user.id

    if @snippet.save
      redirect_to snippet_path(@snippet.unique_id)
    else
      render :new
    end
  end

  def update
    if @snippet.update(snippet_params)
      redirect_to snippet_path(@snippet.unique_id)
    else
      render :edit
    end
  end

  def destroy
    @snippet.destroy
    redirect_to snippets_url
  end

  private

  def set_snippet
    @snippet = Snippet.find_by_unique_id(params[:unique_id])
  end

  def snippet_params
    params.require(:snippet).permit(:title, :content, :description, :proficiency, :private)
  end

  def not_found
    raise ActionController::RoutingError.new("Not Found")
  end
end
