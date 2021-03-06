class EndUser::PostsController < ApplicationController
  before_action :authenticate_end_user!
  before_action :correct_post, only: [:edit]

  def new
    @post_new = Post.new
    @works = @post_new.works.new
    @genres = Genre.all
  end

  def edit
    @draft_post = Post.find(params[:id])
    @genres = Genre.all
  end

  def index
    @order = params["order"]
    @terms = params["terms"]
    posts = Post.sort_for(@order, @terms, current_end_user)
    public_posts = Post.block_posts(posts, current_end_user)
    @public_posts = Kaminari.paginate_array(public_posts).page(params[:page]).per(3)
    @genres = Genre.all
    @comment_new = Comment.new
  end

  def show
    @genres = Genre.all
    @post = Post.find(params[:id])
    favorite_users = @post.favorite_end_user
    @favorite_users = Post.block_action(favorite_users, current_end_user)
    comments = @post.comments
    @comments = Post.block_posts(comments, current_end_user)
    @comment_new = Comment.new
  end

  def create
    @post_new = Post.new(post_params)
    if @post_new.save
      if @post_new.post_status == true
        redirect_to post_path(@post_new.id)
      elsif @post_new.post_status == false
        redirect_to end_user_path(@post_new.end_user)
      end
    else
      @works = @post_new.works.new
      @genres = Genre.all
      render 'new'
    end
  end

  def update
    @draft_post = Post.find(params[:id])
    if @draft_post.update(post_params)
      redirect_to post_path(@draft_post.id)
    else
      @genres = Genre.all
      render 'edit'
    end
  end

  def destroy
    @post = Post.find(params[:id])
    @post.destroy
    redirect_to posts_path
  end

  def correct_post
    post = Post.find(params[:id])
    unless post.end_user_id == current_end_user.id
      redirect_to posts_path
    end
  end

  private

  def post_params
    params.require(:post).permit(:end_user_id, :genre_id, :title, :images, :subtitle, :cost, :creation_time, :level, :caution, :link, :post_status,
                                 materials_attributes: [:id, :post_id, :material_name, :shop], works_attributes: [:id, :post_id, :detail, :images])
  end
end
