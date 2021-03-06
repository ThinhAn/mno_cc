class ProjectRegionUtilityImage < ActiveRecord::Base

	has_attached_file :image, 
		default_url: "/assets/project_region_utilities/:style/default.png", 
		:path => ":rails_root/app/assets/file_uploads/project_region_utility_images/:style/:id_:filename", 
		:url => "/assets/project_region_utility_images/:style/:id_:filename"
	validates_attachment_content_type :image, content_type: /\Aimage\/.*\Z/

	default_scope { order('"order" asc') }
	
end
