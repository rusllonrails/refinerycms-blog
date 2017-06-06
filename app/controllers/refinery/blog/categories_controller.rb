module Refinery
  module Blog
    class CategoriesController < BlogController

      include ::SubdomainHelper

      respond_to :html, :rss, :json

      before_action :redirect_to_root_domain_if_marketplace
      before_action :find_category, :find_all_blog_posts, only: :show
      before_action :add_default_breadcrumbs
      before_action :add_breadcrumbs, :only => [:show]

      def show
        @posts = @category.posts.live.includes(:comments, :categories).with_marketplace(current_marketplace_or_default.id).with_globalize.page(params[:page])

        respond_with (@posts) do |format|
          format.rss { render :layout => false, :template => 'refinery/blog/posts/index' }
          format.html
          format.js
        end
      end

      private

      def find_category
        @category = Refinery::Blog::Category.friendly.find(params[:id])
      end

      def post_finder_scope
        @category.posts
      end

      protected

      def add_default_breadcrumbs
        add_crumb "Home", '/'
        add_crumb "Blog", '/blog'
      end

      def add_breadcrumbs
        add_crumb @category.title, view_context.refinery.blog_category_path(@category)
      end
    end
  end
end
