class ContactRequestResult < ActiveRecord::Base

	# Insert

		# Assign params

			def assign_attributes_with_params _params
				assign_attributes _params.permit [ :contact_result_id, :content ]
			end

		# / Assign params

		# Save with params

		def save_with_params _params
			assign_attributes_with_params _params

			if save
				{ status: 0 }
			else
				{ status: 3 }
			end
		end

		# / Save with params

	# / Insert

end
