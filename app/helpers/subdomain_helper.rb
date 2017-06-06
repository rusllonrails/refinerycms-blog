# module SubdomainHelper
#   def current_marketplace
#     marketplace_domain = Refinery::Marketplaces::MarketplaceDomain.find_by_domain(request.host)
#     if marketplace_domain.present?
#       marketplace_domain.marketplace
#     else
#       nil
#     end
#   end

#   def current_marketplace_or_default
#     current_marketplace || Refinery::Marketplaces::Marketplace.find_by_key(:en)
#   end

#   def is_marketplace?
#     current_marketplace.present?
#   end

#   def marketplace_translation(translation_key)
#     t "marketplace.#{current_marketplace_or_default.key}.#{translation_key}"
#   end

#   def redirect_to_root_domain_if_marketplace
#     if is_marketplace?
#       domain = Rails.application.config.action_controller.asset_host
#       redirect_to "#{request.protocol}#{domain}#{request.fullpath}", :status => :moved_permanently
#     else
#       true
#     end
#   end
# end
