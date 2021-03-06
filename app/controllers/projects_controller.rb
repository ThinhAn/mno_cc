class ProjectsController < ApplicationController
	layout 'layout_front'

	# Index

		# View
		def index
			@favorite_projects = Project.search_with_params(is_favorite: 'true')
			@projects = Project.search_with_params(newest: '')

			render layout: 'front_layout'
		end

		def demo
		end

	# / Index

	# View

		# View
		# params: slug(*)
		def old_view
			id = params[:slug][((params[:slug].rindex('-') || -1) + 1)...params[:slug].length]

			@project = Project.find id

			session[:project_viewed] ||= []
			unless session[:project_viewed].include? id
				@project.update(view_count: @project.view_count + 1)
				session[:project_viewed] << id
			end
		end

		# View
		# params: id(*)
		def view
			id = params[:slug][((params[:slug].rindex('-') || -1) + 1)...params[:slug].length]

			@project = Project.find id

			# Track
			session[:projects_viewed] ||= []
			if !bot? && !session[:projects_viewed].include?(@project.id)
				@project.update(view_count: @project.view_count + 1)
				session[:projects_viewed] << @project.id

				Log.create(
					object_type: 'project',
					object_id: @project.id,
					action: 'view',
					user_type: current_user_type,
					user_id: current_user_id
				)
			end

			render layout: 'front_layout'
		end

	# / View

	# Create

		# View
		# params: id
		def create
			@project = params[:id].present? ? Project.find(params[:id]) : Project.new(create_step: 0)
			
			# Author
			if @project.new_record?
				authorize! :create, @project
			else
				authorize! :edit, @project
			end

			render layout: 'layout_back'
		end

		# Handle => View
		# params: id(*), is_full(*)
		def set_is_full_status
			is_full = params[:is_full] == '1'
			Project.where(id: params[:id]).update_all(is_full: is_full, is_draft: is_full)

			if is_full
				redirect_to "/du-an/dang-chi-tiet/#{params[:id]}"
			else
				redirect_to '/du-an/cua-toi'
			end
		end

		# Handle
		# params: project form
		def save
			is_draft = params.has_key? :draft

			if params[:project][:id].blank?
				params[:project][:user_id] = current_user.id
				project = Project.new
			else 
				project = Project.find(params[:project][:id])
				if project.nil?
					return render json: { status: 1 }
				end
			end
			
			result = project.save_with_params(params[:project], is_draft)

			return render json: result if result[:status] != 0

			render json: {
				status: 0,
				result: project.id
			}
		end

		# View
		# params: id
		def create_details
			@project = Project.find params[:id]

			# Author
			authorize! :edit, @project
			
			render layout: 'layout_back'
		end

		# View
		# params: id(*)
		def setup_interact_images
			@project = Project.find params[:id]

			# Author
			authorize! :edit, @project

			# Update step
			if (@project.create_step < 3)
				@project.create_step = 3
				@project.save
			end

			render layout: 'layout_back'
		end

		# Handle
		# params: id(*), just_check(enum: t/f)
		# return
			# errors: [
			# 	{
			# 		type: enum(project, block, surface),
			# 		id,
			#		alert
			# 	}
			# ]
		def setup_interact_images_finish
			project = Project.find params[:id]

			# Author
			authorize! :edit, project

			errors = []

			# Check block (project image must point to all blocks)
			project.blocks.each do |block|
				unless ProjectImageBlockDescription.exists? block_id: block.id
					errors << {
						type: 'project',
						name: block.display_name,
						id: ''
					}
				end

				# Check block floor (block image must point to all block floors)
				block.floors.each do |floor|
					unless BlockImageBlockFloorDescription.exists? block_floor_id: floor.id
						errors << {
							type: 'block',
							id: block.id,
							name: floor.display_name
						}
					end
				end if block.has_floor

				# Check real-estate (block floor image must point to all real-estates)
				block.real_estates.each do |re|
					unless BlockFloorSurfaceRealEstateDescription.exists? real_estate_id: re.id
						errors << {
							type: 'surface',
							id: block.id,
							name: re.short_label
						}
					end
				end
			end

			if errors.length == 0 && params[:just_check] != 't'
				project.blocks.each do |block|
					next unless block.has_floor

					block.real_estates.each do |re|
						re.build_in_floors
					end

					floors = []
					block.floors.each do |floor|
						floors.concat floor.floors
					end
					block.floor_number = floors.max

					block.save
				end
				project.create_step = 4
				project.save

				return render json: { status: 0 }
			end

			render json: { status: 5, result: errors }
		end

	# / Create

	# Interact image

		# Get values
		# params: id(*)
		# return
			# {
			# 	images: [
			# 		{
			# 			id, 
			# 			url, 
			# 			thumb_url, 
			# 			descriptions: [
			# 				{
			# 					id,
			# 					tag_name,
			# 					points (if polyline)
			# 					description: {
			# 						type,
			# 						id (if block),
			# 						data (if text_image): {
			# 							description,
			# 							images: [
			# 								{
			# 									id,
			# 									url,
			# 									description,
			# 									is_avatar
			# 								}
			# 							]
			# 						}
			# 					}
			# 				}
			# 			]
			# 		}
			# 	]
			# }
		def get_image_for_interact_build
			project = Project.find params[:id]

			# Author
			authorize! :edit, project

			# Result for request
			images = []

			# Get project's image
			project_images = ProjectImage.where(project_id: params[:id])

			# Get all info of each image
			project_images.each do |project_image|
				image = {}

				# Get url for display
				image[:id] = project_image.id
				image[:url] = project_image.image.url
				image[:thumb_url] = project_image.image.url('thumb')

				if project_image.image_descriptions.present?
					image[:descriptions] = []

					project_image.image_descriptions.each do |image_description|
						description = { id: image_description.id, tag_name: image_description.area_type }

						# Area info
						case image_description.area_type
						when 'polyline'
							description[:points] = image_description.area_info['points']
						else
							next
						end

						# Description info
						description[:description] = { type: image_description.description_type }
						case image_description.description_type
						when 'block'
							description[:description][:id] = image_description.block_description.block_id
						when 'text_image'
							description[:description][:data] = {}
							if image_description.text_description.present?
								description[:description][:data][:description] = image_description.text_description.description
							end

							if image_description.image_descriptions.present?
								image_data = []
								image_description.image_descriptions.each do |data|
									image_data << { id: data.id, url: data.image.url, description: data.description, is_avatar: data.is_avatar }
								end
								description[:description][:data][:images] = image_data.to_json
							end
						end

						image[:descriptions] << description
					end
				end

				images << image
			end

			render json: { status: 0, result: images }
		end

		# Handle
		# params: data(*)
		def save_interact_images
			render json: ProjectImage.save_description(JSON.parse(params[:data]))
		end

		# Get values
		# params: id(*)
		def get_data_for_interact_view

			@project = Project.find params[:id]

			# Images

				# Result for request
				images = []

				# Get project's image
				project_images = ProjectImage.where(project_id: params[:id])

				# Get all info of each image
				project_images.each do |project_image|
					image = {}

					# Get url for display
					image[:url] = project_image.image.url

					if project_image.image_descriptions.present?
						image[:descriptions] = []

						project_image.image_descriptions.each do |image_description|
							description = { tag_name: image_description.area_type }

							# Area info
							case image_description.area_type
							when 'polyline'
								description[:points] = image_description.area_info['points']
							else
								next
							end

							# Description info
							description[:description] = { type: image_description.description_type }
							case image_description.description_type
							when 'block'
								description[:description][:id] = image_description.block_description.block_id
								description[:description][:description] = image_description.block_description.block.display_name
							when 'text_image'
								description[:description][:data] = {}
								if image_description.text_description.present?
									description[:description][:description] = image_description.text_description.description
								end

								# if image_description.image_descriptions.present?
								# 	image_data = []
								# 	image_description.image_descriptions.each do |data|
								# 		image_data << { id: data.id, url: data.image.url, description: data.description, is_avatar: data.is_avatar }
								# 	end
								# 	description[:description][:data][:images] = image_data.to_json
								# end
							end

							image[:descriptions] << description
						end
					end

					images << image
				end

			# / Images

			# Navigator
			
				navigator = {
					display_floor: false,
					display_position: false
				}
			
			# / Navigator

			# Info

				info = render_to_string(partial: 'projects/info_for_interact_view')

			# / Info

			render json: { 
				status: 0, 
				result: {
					images: images,
					info: info,
					navigator: navigator
				} 
			}
		end

	# / Interact image

	# My list

		# View
		def my
			# Author
			authorize! :view_my, Project

			@projects = Project.my_search_with_params interact: 'desc'

			render layout: 'layout_back'
		end

		# Partial view
		# params: keyword
		def _my_list
			# Author
			authorize! :view_my, Project

			per = Rails.application.config.item_per_page
			
			params[:page] ||= 1
			params[:page] = params[:page].to_i

			projects = Project.my_search_with_params params

			count = projects.count

			return render json: { status: 1 } if count === 0

			render json: {
				status: 0,
				result: {
					list: render_to_string(partial: 'projects/my_list', locals: { projects: projects.page(params[:page], per) }),
					pagination: render_to_string(partial: 'shared/pagination', locals: { total: count, per: per, page: params[:page] })
				}
			}
		end

		def change_show_status
			Project.update_show_status params[:id], params[:is_show]

			render json: { status: 0 }
		end

	# / My list

	# My favorite list

		# View
		def my_favorite
			# Author
			authorize! :view_my, Project

			@projects = Project.my_favorite_search_with_params interact: 'desc'

			render layout: 'layout_back'
		end

		# Partial view
		# params: keyword, page
		def _my_favorite_list
			# Author
			authorize! :view_my, Project

			per = Rails.application.config.item_per_page

			params[:page] ||= 1
			params[:page] = params[:page].to_i

			projects = Project.my_favorite_search_with_params params

			count = projects.count

			return render json: { status: 1 } if count === 0

			render json: {
				status: 0,
				result: {
					list: render_to_string(partial: 'projects/my_favorite_list', locals: { projects: projects.page(params[:page], per) }),
					pagination: render_to_string(partial: 'shared/pagination', locals: { total: count, per: per, page: params[:page] })
				}
			}
		end

	# / My favorite list

	# Pending

		# View
		def pending
			# Author
			authorize! :manage, Project

			@projects = Project.pending_search_with_params interact: 'desc'

			render layout: 'layout_back'
		end

		# Partial view
		# params: keyword
		def _pending_list
			# Author
			return render json: { staus: 6 } if cannot? :manage, Project

			per = Rails.application.config.item_per_page
			
			params[:page] ||= 1
			params[:page] = params[:page].to_i

			ps = Project.pending_search_with_params params

			count = ps.count

			return render json: { status: 1 } if count === 0

			render json: {
				status: 0,
				result: {
					list: render_to_string(partial: 'projects/pending_list', locals: { projects: ps.page(params[:page], per) }),
					pagination: render_to_string(partial: 'shared/pagination', locals: { total: count, per: per, page: params[:page] })
				}
			}
		end

		# Handle
		# params: id(*)
		def approve   
			render json: Project.update_pending_status(params[:id], 0)
		end

	# / Pending

	# Manager

		def manager
			# Author
			authorize! :manage, Project

			@projects = Project.manager_search_with_params interact: 'desc'

			render layout: 'layout_back'
		end

		# Partial view
		# params: keyword, page
		def _manager_list
			# Author
			authorize! :manage, Project

			per = Rails.application.config.item_per_page

			params[:page] ||= 1
			params[:page] = params[:page].to_i

			projects = Project.manager_search_with_params params

			count = projects.count

			return render json: { status: 1 } if count == 0

			render json: {
				status: 0,
				result: {
					list: render_to_string(partial: 'projects/manager_list', locals: { projects: projects.page(params[:page], per) }),
					pagination: render_to_string(partial: 'shared/pagination', locals: { total: count, per: per, page: params[:page] })
				}
			}
		end

		# Handle
		# params: id, is_force_hide
		def change_force_hide_status
			Project.update_force_hide_status params[:id], params[:is_force_hide]

			render json: { status: 0 }
		end


		# Handle
		# params: id, is_favorite
		def change_favorite_status
			Project.update_favorite_status params[:id], params[:is_favorite]

			render json: { status: 0 }
		end

	# / Manager

	# Products manage
	
		# View
		# params: id(*)
		def products_manage
			@project = Project.find params[:id]

			# Author
			authorize! :edit, @project

			render layout: 'layout_back'
		end

		# Partial view
		# params: search form, page
		def _products_manage_list
			project = Project.find params[:search][:id]

			# Author
			authorize! :edit, project

			products = Project.product_search_with_params params[:search]

			return render json: { status: 1 } if products[:real_estates].blank? && products[:floor_real_estates].blank?

			# Paging
			per = 30
			count = products[:real_estates].count + products[:floor_real_estates].count
			params[:page] ||= 1
			page = params[:page].to_i
			if products[:real_estates].present?
				offset = (page - 1) * per

				if offset >= products[:real_estates].count
					offset -= products[:real_estate].count
					products[:real_estates] = []
					products[:floor_real_estates] = products[:floor_real_estates].offset(offset).limit(per)
				else
					products[:real_estates] = products[:real_estates].offset(offset).limit(per)
					if products[:real_estate].count == per
						products[:floor_real_estates] = []
					else
						limit = per - products[:real_estates].count
						products[:floor_real_estates].limit(limit)
					end
				end
			else
				products[:floor_real_estates] = products[:floor_real_estates].page page, per
			end

			render json: {
				status: 0,
				result: {
					list: render_to_string(partial: 'products_list', locals: { products: products }),
					pagination: render_to_string(partial: 'shared/pagination', locals: { page: page, per: per, total: count })
				}
			}
		end

		# Handle
		# params: product_id, product_type, product_status
		def set_product_status
			project = nil

			case params[:product_type]
			when 'real_estate'
				project = Project.joins(blocks: :real_estates).where("real_estates.id = #{params[:product_id]}").first
			when 'floor_real_estate'
				project = Project.joins(blocks: { real_estates: :in_floors }).where("floor_real_estates.id = #{params[:product_id]}").first
			end

			return render json: { status: 1 } if project.blank?

			# Author
			authorize! :edit, project

			result = Project.set_product_status project.id, params[:product_type], params[:product_id], params[:product_status]

			render json: result
		end
	
	# / Products manage

	# Request manage
	
		# View
		def requests_manage
			# Author
			authorize! :manage, Project

			@requests = ContactRequest.project_contact.need_contact

			render layout: 'layout_back'
		end

		# Partial view
		# params: page
		def _requests_manage_list
			# Author
			authorize! :manage, Project

			requests = ContactRequest.project_contact.need_contact

			page = params[:page] || 1
			per = 20
			count = requests.count

			render json: {
				status: 0,
				result: {
					list: render_to_string(partial: 'requests_manage_list', locals: { requests: requests.page(page, per) }),
					pagination: render_to_string(partial: 'shared/pagination', locals: { total: count, per: per, page: page })
				}
			}
		end

		# Partial view
		# params: user_type, user_id
		def _request_manage_user_info
			# Author
			authorize! :manage, Project

			case params[:user_type]
			when 'user'
				render json: {
					status: 0,
					result: render_to_string(partial: 'users/info_popup', locals: { user: User.find(params[:user_id]) })
				}
			when 'contact_user'
				render json: {
					status: 0,
					result: render_to_string(partial: 'contact_user_infos/info_popup', locals: { contact_user: ContactUserInfo.find(params[:user_id]) })
				}
			else
				render json: { status: 1 }
			end
		end
	
	# / Request manage

	# Delete

		# Handle
		# params: id(*)
		def delete
			render json: Project.delete_by_id(params[:id])
		end

	# / Delete

	# Search

		# Partial view
		# params: 
		#   list_type, per, price(x;y), page, district
		#   newest
		def search
			projects = Project.search_with_params params
			
			params[:per] ||= Rails.application.config.real_estate_item_per_page
			params[:per] = params[:per].to_i

			params[:page] ||= 1
			params[:page] = params[:page].to_i

			return render json: { status: 1 } if projects.count == 0

			render json: {
				status: 0,
				result: {
					list: render_to_string(partial: 'projects/item_list', locals: { projects: projects.page(params[:page], params[:per]), type: params[:list_type].to_i }),
					pagination: render_to_string(partial: 'shared/pagination_2', locals: { total: projects.count, per: params[:per], page: params[:page] })
				}
			}
		end

	# / Search

	# Gallery

		# Handle
		# params: id
		def get_gallery
			images = ProjectImage.where(project_id: params[:id]).reorder('"order" asc')

			render json: { status: 0, result: images.map { |image| { id: image.id, small: image.image.url(:thumb), original: image.image.url, description: image.description } } }
		end

	# / Gallery

	# Favorite

		# Handle
		# params: id, is_add
		def user_favorite
			if params[:is_add] == '1'
				render json: UsersFavoriteProject.add_favorite(params[:id])
			else
				render json: UsersFavoriteProject.remove_favorite(params[:id])
			end
		end

	# / Favorite

end
