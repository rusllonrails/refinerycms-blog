module Refinery
  module Blog
    module Admin
      class CommentsController < ::Refinery::AdminController

        crudify :'refinery/blog/comment',
                :title_attribute => :name,
                :order => 'published_at DESC'

        def index
          @comments = Refinery::Blog::Comment.unmoderated.order('created_at DESC').page(params[:page])
          render :index
        end

        def approved
          @comments = Refinery::Blog::Comment.approved.order('created_at DESC').page(params[:page])
          render :index
        end

        def approve
          @comment = Refinery::Blog::Comment.find(params[:id])
          @comment.approve!
          flash[:notice] = t('approved', :scope => 'refinery.blog.admin.comments', :author => @comment.name)

          redirect_to refinery.blog_admin_comments_path
        end

        def rejected
          @comments = Refinery::Blog::Comment.rejected.order('created_at DESC').page(params[:page])
          render :index
        end

        def reject
          @comment = Refinery::Blog::Comment.find(params[:id])
          @comment.reject!
          flash[:notice] = t('rejected', :scope => 'refinery.blog.admin.comments', :author => @comment.name)

          redirect_to refinery.blog_admin_comments_path
        end
      end
    end
  end
end
