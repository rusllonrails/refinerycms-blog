module Refinery
  module Blog
    class Category < ActiveRecord::Base
      extend FriendlyId

      translates :title, :slug

      friendly_id :title, :use => [:slugged, :globalize]

      has_many :categorizations, :dependent => :destroy, :foreign_key => :blog_category_id
      has_many :posts, :through => :categorizations, :source => :blog_post

      validates :title, :presence => true, :uniqueness => true

      def self.by_title(title)
        find_by(title: title)
      end

      def self.translated
        with_translations(::Globalize.locale)
      end

      def post_count
        posts.live.count
      end

      def highlighted_post
        post = posts.highlighted.first
        post ||= posts.first
        post
      end

      # how many items to show per page
      self.per_page = Refinery::Blog.posts_per_page

    end
  end
end
