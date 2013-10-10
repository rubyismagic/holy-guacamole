class CommentsController < ApplicationController
  # POST /comments
  # POST /comments.json
  def create
    @comment = Comment.new(comment_params)
    @post = PostsCollection.by_key(params[:post_id])
    @post.comments << @comment

    respond_to do |format|
      if PostsCollection.replace(@post)
        format.html { redirect_to @post, notice: 'Thanks for your comment.' }
      else
        format.html { render action: 'new' }
      end
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:user_name, :body)
  end
end
