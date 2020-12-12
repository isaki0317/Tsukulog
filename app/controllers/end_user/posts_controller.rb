class EndUser::PostsController < ApplicationController

  def new
    @post_new = Post.new
    @works = @post_new.works.new
    # @post_new.materials.new
    @genres = Genre.all
  end

  def edit
    @draft_post = Post.find(params[:id])
    @works = @draft_post.works
    @genres = Genre.all
  end

  def index
    @order = params["order"]
    @terms = params["terms"]
    posts = Post.sort_for(@order, @terms)
    public_posts = posts.where(post_status: "true")
    @public_posts = public_posts.page(params[:page]).per(2)
    @genres = Genre.all
    @comment_new = Comment.new
  end

  def show
    @genres = Genre.all
    @post = Post.find(params[:id])
    @comment_new = Comment.new
  end

  def create
    @post_new = Post.new(post_params)
    @post_new.save
    if @post_new.post_status == true
      redirect_to post_path(@post_new.id)
    elsif @post_new.post_status == false
      redirect_to end_user_path(@post_new.end_user)
    end
  end

  private
  def post_params
    params.require(:post).permit(:end_user_id, :genre_id, :title, :images, :subtitle, :cost, :creation_time, :level, :caution, :link, :post_status,
    materials_attributes: [:post_id, :material_name, :shop], works_attributes: [:post_id, :detail, :images])
  end

end
