class AppraisalCompany < ActiveRecord::Base

  include PgSearch
  pg_search_scope :search, against: [:name]

# Associate

	belongs_to :avatar_image, class_name: 'Image'
	belongs_to :representative, class_name: 'User'

  has_many :appraisal_companies_real_estates
  has_many :real_estates, through: :appraisal_companies_real_estates
  
  has_and_belongs_to_many :users

# / Associate

# Validate
	
  validates :name, presence: { message: 'Tên công ty không thể bỏ trống' }
  validates :representative_id, presence: { message: 'Người đại diện không thể bỏ trống' }

# / Validate

# Insert

	# Get params

	def self.get_params params
		params.permit [
			:name, :representative_id, :avatar_image_id
		]
	end

	# / Get params

	# Save with params

	def save_with_params params
		# Author
		if new_record?
			return { status: 6 } if User.current.cannot? :create, AppraisalCompany
		else
			return { status: 6 } if User.current.cannot? :edit, self
		end

		ac_params = AppraisalCompany.get_params params

		assign_attributes ac_params

		if save
			{ status: 0 }
		else
			{ status: 3 }
		end
	end

	# / Save with params

# / Insert

# Get

	def self.current
  	@current_appraisal_company ||= AppraisalCompany.where(representative_id: User.current.id).first
  end

	def self.get_assigned_real_estates_by_current_user
		ac = current

		RealEstate.joins(:appraisal_companies_real_estates).where({
			'appraisal_companies_real_estates.appraisal_company_id' => ac.id,
			'appraisal_companies_real_estates.is_assigned' => true
		})
	end

# / Get

# Delete
  
  def self.delete_by_id id
    ac = find id

    return { status: 1 } if ac.nil?

    return { status: 6 } if User.current.cannot? :delete, ac

    delete id

    { status: 0 }
  end

# / Delete

end
