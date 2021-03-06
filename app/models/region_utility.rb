class RegionUtility < ActiveRecord::Base
	
	serialize :options, JSON

	def self.get_options
		order order: 'ASC'
	end

	def display_name
		@display_name ||= name.present? ? I18n.t("region_utility.text.#{name}") : ''
	end

end
