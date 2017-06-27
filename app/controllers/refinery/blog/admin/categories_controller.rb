module Refinery
  module Blog
    module Admin
      class CategoriesController < ::Refinery::AdminController

        include ::SubdomainHelper

        crudify :'refinery/blog/category',
                :include => [:translations],
                :order => 'title ASC'

        private

        def category_params
          params.require(:category).permit(:title, :excerpt)
        end
      end
    end
  end
end
