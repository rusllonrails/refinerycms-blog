module Refinery
  module Blog
    class PostsController < BlogController

      include ::SubdomainHelper

      respond_to :html, :js, :rss, :json

      before_action :redirect_to_root_domain_if_marketplace
      before_action :find_blog_post, :only => [:show, :comment, :update_nav, :vote]
      before_filter :find_tags
      before_action :find_related_posts, :only => [:show]
      before_action :set_voter, :only => [:vote]
      before_action :add_default_breadcrumbs
      before_action :add_breadcrumbs, :only => [:show]
      before_action :set_voting_key, :only => [:show, :vote]
      before_action :set_og_meta, :only => [:show]
      before_action :set_form_loaded_at, :only => [:show]
      before_action :flood_prevention, :only => [:comment]
      before_action :find_all_blog_posts, :except => [:archive]

      def index
        if stale?(etag: @posts.first, last_modified: @posts.maximum(:updated_at))
          respond_with (@posts) do |format|
            format.html
            format.rss { render :layout => false }
          end
        end
      end

      def vote
        if user_can_vote?
          @voter.vote_for(@post)
          cookies[self.voting_key] = @post.id
        end
        respond_to do |format|
          format.html { redirect_to refinery.blog_post_url(@post) }
          format.json { render :json => {:for_count => @post.votes_for, :against_count => @post.votes_against } }
        end
      end

      def voting_key
        "blog_#{@post.id}"
      end

      def show
        @comment = Comment.new

        @canonical = refinery.url_for(:locale => Refinery::I18n.current_frontend_locale) if canonical?

        @post.increment!(:access_count, 1)

        respond_with (@post) do |format|
          format.html { present(@post) }
          format.js { render :partial => 'post', :layout => false }
        end
      end

      def comment
        @comment = @post.comments.create(comment_params)
        if @comment.valid?
          if Comment::Moderation.enabled? or @comment.ham?
            begin
              CommentMailer.notification(@comment, request).deliver_now
            rescue
              logger.warn "There was an error delivering a blog comment notification.\n#{$!}\n"
            end
          end

          if Comment::Moderation.enabled?
            flash[:notice] = t('thank_you_moderated', :scope => 'refinery.blog.posts.comments')
            redirect_to refinery.blog_post_url(params[:id])
          else
            flash[:notice] = t('thank_you', :scope => 'refinery.blog.posts.comments')
            redirect_to refinery.blog_post_url(params[:id],
                                      :anchor => "comment-#{@comment.to_param}")
          end
        else
          render :show
        end
      end

      def archive
        if params[:month].present?
          date = "#{params[:month]}/#{params[:year]}"
          archive_date = Time.parse(date)
          @date_title = ::I18n.l(archive_date, :format => '%B %Y')
          @posts = Post.live.by_month(archive_date).page(params[:page])
        else
          date = "01/#{params[:year]}"
          archive_date = Time.parse(date)
          @date_title = ::I18n.l(archive_date, :format => '%Y')
          @posts = Post.live.by_year(archive_date).page(params[:page])
        end
        respond_with (@posts)
      end

      def tagged
        @tag = ActsAsTaggableOn::Tag.find(params[:tag_id])
        @tag_name = @tag.name
        @posts = Post.live.newest_first.uniq.tagged_with(@tag_name).page(params[:page])
      end

    private

      def comment_params
        params.require(:comment).permit(:name, :email, :message)
      end

    protected

      def canonical?
        Refinery::I18n.default_frontend_locale != Refinery::I18n.current_frontend_locale
      end

      def set_form_loaded_at
        session[:form_loaded_at] = Time.now.to_i
      end

      def flood_prevention
        time_elapsed = Time.now.to_i - session[:form_loaded_at].to_i
        redirect_to refinery.blog_post_url(@post) if time_elapsed < 5
      end

      def add_default_breadcrumbs
        add_crumb 'Home', '/'
        add_crumb 'Blog', '/blog'
      end

      def set_voter
        @voter = current_website_user ? current_website_user : Refinery::Websites::User.first
      end

      def find_related_posts
        @related = @post.related
      end

      def add_breadcrumbs
        add_crumb @post.title, view_context.refinery.blog_post_path(@post)
      end

      def user_can_vote?
        !cookies[self.voting_key]
      end

      def set_voting_key
        @voting_key = self.voting_key
      end

      def set_og_meta
        @page.open_graph_title = @post.title
        @page.open_graph_description = @post.body
        @page.open_graph_image = @post.feature_image.url if @post.feature_image
      end

      def find_all_blog_posts
        @posts = Refinery::Blog::Post.live
                                     .includes(:comments, :categories)
                                     .with_marketplace(current_marketplace_or_default.id)
                                     .where("published_at IS NOT NULL")
                                     .order(published_at: :desc)
                                     .with_globalize
                                     .page(params[:page])
      end

      def find_blog_post
        unless (@post = Refinery::Blog::Post.with_globalize.find_by_slug(params[:id])).try(:live?)
          if refinery_user? and current_refinery_user.authorized_plugins.include?("refinerycms_blog")
            @post = Refinery::Blog::Post.with_globalize.find_by_slug(params[:id])
          else
            error_404
          end
        end
      end
    end
  end
end


