class RealEstatesController < ApplicationController
	layout 'layout_front'

	def index
		@favorite_res = RealEstate.search_with_params(is_favorite: 'true')
		@res = RealEstate.search_with_params(newest: '')

		render layout: 'front_layout'
	end

	def demo
	end

	def estimate
	end

	def category

	end

	# List

		private def get_search_param_from_keyword search
			case search

			when 'dat-tho-cu'
				{ search_name: 'Đất thổ cư', real_estate_type: 'residential_land' }
			when 'dat-nong-nghiep'
				{ search_name: 'Đất nông nghiệp', real_estate_type: 'vacant_land' }
			when 'dat-lam-nghiep'
				{ search_name: 'Đất lâm nghiệp', real_estate_type: 'forest_land' }
			when 'dat-san-xuat'
				{ search_name: 'Đất cho sản xuất', real_estate_type: 'productive_land' }
			when 'dat-du-an'
				{ search_name: 'Đất dự án', real_estate_type: 'project_land' }
			when 'van-phong'
				{ search_name: 'Văn phòng', real_estate_type: 'office' }
			when 'phong-tro'
				{ search_name: 'Phòng trọ', real_estate_type: 'motel' }
			when 'mat-bang-cua-hang'
				{ search_name: 'Mặt bằng - Cửa hàng', real_estate_type: 'store' }
			when 'nha-hang-khach-san'
				{ search_name: 'Nhà hàng - Khách sạn', real_estate_type: 'restaurant_hotel' }
			when 'nha-kho-xuong'
				{ search_name: 'Kho - Xưởng', real_estate_type: 'storage_workshop' }
			when 'can-ho-cao-cap'
				{ search_name: 'Căn hộ cao cấp', real_estate_type: 'high_apartment' }
			when 'can-ho-trung-binh'
				{ search_name: 'Căn hộ trung bình', real_estate_type: 'medium_apartment' }
			when 'can-ho-thap'
				{ search_name: 'Căn hộ thu nhập thấp', real_estate_type: 'low_apartment' }
			when 'nha-o-xa-hoi'
				{ search_name: 'Nhà ở xã hội', real_estate_type: 'social_home' }
			when 'biet-thu'
				{ search_name: 'Biệt thự', real_estate_type: 'villa' }
			when 'nha-pho'
				{ search_name: 'Nhà phố', real_estate_type: 'town_house' }

			when 'nha-tam'
				{ search_name: 'Nhà tạm', constructional_level: 'temporary' }
			when 'nha-cap-4'
				{ search_name: 'Nhà nát tiện xây mới', constructional_level: 'level_4' }

			when 'can-ho-co-ho-boi'
				{ search_name: 'Căn hộ có hồ bơi', real_estate_type: 'apartment', utilities: { pool: '' } }
			when 'nha-pho-duoi-1-ty' 
				{ search_name: 'Nhà phố dưới 1 tỷ', real_estate_type: 'town_house', price: '0;1000000000', }

			else
				{}
			end
		end

		# View
		# params: search params
		def list
			if params[:user_id].present?
				params[:search] ||= {}
				params[:search][:user_id] = params[:user_id]
			end

			return redirect_to '/bat-dong-san' if params[:search].blank?

			if params[:search].is_a? String
				search_params = get_search_param_from_keyword(params[:search]) 

				@search_name = search_params[:search_name]
			else
				search_params = params[:search]

				@search_name = 'Danh sách của ' + User.find(search_params[:user_id]).full_name if params[:search][:user_id].present?
			end

			search_params[:is_favorite] = 'true'
			@favorite_res = RealEstate.search_with_params search_params.clone

			search_params[:is_favorite] = 'false'
			@res = RealEstate.search_with_params search_params.clone

			render layout: 'front_layout'
		end

		# Partial view
		# params: search params, page
		def _list_list
			params[:per] ||= 8
			params[:per] = params[:per].to_i

			params[:page] ||= 1
			params[:page] = params[:page].to_i

			params[:type] ||= 1
			params[:type] = params[:type].to_i

			res = RealEstate.search_with_params params[:search]

			count = res.count

			return render json: { status: 1 } if count == 0

			render json: {
				status: 0,
				result: {
					list: render_to_string(partial: 'real_estates/item_list', locals: { res: res.page(params[:page], params[:per]), type: params[:type] }),
					pagination: render_to_string(partial: 'shared/pagination_2', locals: { total: count, per: params[:per], page: params[:page] })
				}
			}
		end

	# / List

	# View
		
		# View
		# params: slug(*)
		def view
			# Get id from slug
			id = params[:slug][((params[:slug].rindex('-') || -1) + 1)...params[:slug].length]

			@re = RealEstate.find id

			return redirect_to "/bat-dong-san/#{@re.full_slug}" if @re.full_slug != params[:slug] + '.html'

			# Author
			authorize! :view, @re

			# Track
			session[:res_viewed] ||= []
			if !bot? && !session[:res_viewed].include?(@re.id)
				session[:res_viewed] << @re.id
				@re.update(view_count: @re.view_count + 1)

				Log.create(
					object_type: 'real_estate',
					object_id: @re.id,
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
		# params: id (if edit), p (purpose when click from home)
		def create
			@re = params[:id].present? ? RealEstate.find(params[:id]) : RealEstate.new

			# Check if purpose
			if @re.new_record? && params[:p].present?
				@re.purpose = Purpose.where(code:
					case params[:p]
					when 's'
						'sell'
					when 'r'
						'rent'
					when 't'
						'transfer'
					else
						nil
					end
				).first
			end
			
			# Author
			if @re.new_record?
				authorize! :create, RealEstate
				@is_appraisal = params[:appraisal] == true
			else
				authorize! :edit, @re
				@is_appraisal = @re.appraisal_type != 0
			end

			render layout: 'layout_back'
		end  

		# Handle
		# params: real_estate form
		def save
			is_draft = params.has_key? :draft
			re = params[:real_estate][:id].present? ? RealEstate.find(params[:real_estate][:id]) : RealEstate.new

			if signed?
				# If signed => save with current user
				params[:real_estate][:user_id] = current_user.id

				result = re.save_with_params(params[:real_estate], is_draft)

				return render json: result if result[:status] != 0

				render json: {
					status: 0,
					result: re.id, 
					images: re.images.map{ |image| image.id }, 
				}
			else
				# If not signed => get contact info
				contact_user = params[:contact][:id].present? ? ContactUserInfo.find(params[:contact][:id]) : ContactUserInfo.new

				result = contact_user.save_with_params params[:contact], params[:contact][:id].present?
				if result[:status] == 5
					# If exists data => confirm
					return render json: {
						status: 5,
						result: {
							same_contact: result[:result].to_json(only: [:id]),
							html: render_to_string(partial: 'contact_user_infos/same_contact', locals: { code: result[:code], same_contact: result[:result] })
						}
					}
				end

				# Save cookie, session contact info
				cookies[:contact_user_id] = {
					value: contact_user.id,
					expires: 3.months.from_now
				}
				session[:contact_user_id] = contact_user.id

				# Save with contact user
				params[:real_estate][:user_id] = contact_user.id
				params[:real_estate][:user_type] = 'contact_user'

				result = re.save_with_params(params[:real_estate], is_draft)

				return render json: result if result[:status] != 0

				if params[:real_estate][:id].blank?
					RealEstateMailer.active(re).deliver_later
				end

				render json: { 
					status: 0, 
					result: re.id, 
					images: re.images.map{ |image| image.id }, 
					secure_code: re.params['secure_code']
				}
			end

			# Log
			Log.create(
				object_type: 'real_estate',
				object_id: re.id,
				action: params[:real_estate][:id].present? ? 'edit' : 'create',
				user_type: current_user_type,
				user_id: current_user_id
			)

			Notification.create_new(
				object_type: 'real_estate',
				object_id: re.id,
				action: params[:real_estate][:id].present? ? 'edit' : 'create',
				user_type: current_user_type,
				user_id: current_user_id
			)
		end

		# Handle => View
		# params: id, secure_code
		def active
			result = RealEstate.active params[:id], params[:secure_code]

			return redirect_to '/' if result[:status] != 0

			@status = result[:result]
			render layout: 'layout_back'
		end

	# / Create

	# Block create

		# Partial view
		# params: block_id(*), group_id(*)
		def _block_create
			@block = Block.find params[:block_id]

			# Author
			authorize! :edit, @block.project

			@selected_group = BlockRealEstateGroup.find params[:group_id]
			@re = RealEstate.new

			render json: { status: 0, result: render_to_string(partial: 'real_estates/block_create') }
		end

		# Partial view
		# params: id(*)
		def _block_edit
			@re = RealEstate.find(params[:id])
			@selected_group = @re.block_group
			@block = @re.block

			# Author
			authorize! :edit, @block.project

			render json: { status: 0, result: render_to_string(partial: 'real_estates/block_create') }
		end

		# Handle
		# params: real_estate form
		def block_save
			params[:real_estate][:user_id] = current_user.id

			re = params[:real_estate][:id].blank? ? RealEstate.new : RealEstate.find(params[:real_estate][:id])

			# Author
			authorize! :edit, re.block.project

			result = re.block_save_with_params params[:real_estate]

			return render json: result if result[:status] != 0

			render json: { 
				status: 0, 
				result: render_to_string(partial: 'real_estates/block_item_list', locals: { res: [re] })
			}
		end

		# Handle
		# params: project_id(*), label(*), id
		def check_unique_label
			block_ids = Block.where(project_id: params[:project_id]).map{ |block| block.id }
			exist_re = RealEstate.where(block_id: block_ids, label: params[:label]).first

			if exist_re.present?
				if params[:id].present? && exist_re.id == params[:id].to_s
					render json: { status: 0, result: true }
				else
					render json: { status: 0, result: false }
				end
			else
				render json: { status: 0, result: true }
			end
		end

	# / Block create

	# Block list

		# Partial view
		# params: block_id(*)
		def _block_item_list
			groups = BlockRealEstateGroup.where block_id: params[:block_id]

			render json: {
				status: 0,
				result: render_to_string(partial: 'real_estates/block_item_list', locals: { groups: groups })
			}
		end

		# Partial view
		# params: block_id(*)
		def _block_description_item_list
			groups = BlockRealEstateGroup.where block_id: params[:block_id]

			render json: {
				status: 0,
				result: render_to_string(partial: 'real_estates/block_description_item_list', locals: { groups: groups })
			}
		end

	# / Block list

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
		def groups_get_image_for_interact_build
			# Result for request
			images = []

			# Get block's image
			real_estate_group_images = BlockRealEstateGroupImage.where(block_real_estate_group_id: params[:id])

			# Get all info of each image
			real_estate_group_images.each do |real_estate_group_image|
				image = {}

				# Get url for display
				image[:id] = real_estate_group_image.id
				image[:url] = real_estate_group_image.image.url
				image[:thumb_url] = real_estate_group_image.image.url('thumb')

				if real_estate_group_image.image_descriptions.present?
					image[:descriptions] = []

					real_estate_group_image.image_descriptions.each do |image_description|
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

			render json: BlockRealEstateGroupImage.save_description(JSON.parse(params[:data]))
		end

		# Get values
		# params: id(*)
		def groups_get_data_for_interact_view

			@group = BlockRealEstateGroup.find params[:id]

			# Images

				# Result for request
				images = []

				# Get group's image
				real_estate_group_images = BlockRealEstateGroupImage.where(block_real_estate_group_id: params[:id])

				# Get all info of each image
				real_estate_group_images.each do |real_estate_group_image|
					image = {}

					# Get url for display
					image[:url] = real_estate_group_image.image.url

					if real_estate_group_image.image_descriptions.present?
						image[:descriptions] = []

						real_estate_group_image.image_descriptions.each do |image_description|
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

			# Info

				info = render_to_string(partial: 'real_estates/groups/info_for_interact_view')

			# / Info

			# Navigator
			
				navigator = {
					block: {
						id: @group.block.id,
						name: @group.block.display_name
					},
					group: {
						id: @group.id,
						name: @group.display_name
					}
				}

				if @group.block.block_type.present?
					unless @group.block.has_floor
						navigator[:floor] = {
							id: @group.block.floors.first.id,
							name: @group.block.floors.first.display_name
						}
						navigator[:display_position] = false
					end
				end

			# / Navigator

			render json: { 
				status: 0, 
				result: {
					images: images,
					info: info,
					navigator: navigator
				} 
			}
		end

		# Get values
		# params: id(*)(block_id)
		def groups_get_options_for_interact_view
			groups = BlockRealEstateGroup.where block_id: params[:id]

			options = []
			groups.each do |group|
				floor_ids = '|' + group.real_estates.group_by{ |re| re.block_floor_id }.keys.join('|') + '|'
				options << {
					id: group.id,
					name: group.display_name,
					floor_ids: floor_ids
				}
			end

			render json: { status: 0, result: options }
		end

		# Get values
		# params: id(*)
		def get_data_for_interact_view

			@re = RealEstate.find params[:id]

			# Images

				# Result for request
				images = []

				# Surface
				
					# Get all info of surface
					image = {}

					# Get url for display
					image[:url] = @re.block_floor.surface.url

					if @re.block_floor.surface_descriptions.present?
						image[:descriptions] = []

						@re.block_floor.surface_descriptions.each do |surface_description|
							description = { tag_name: surface_description.area_type }

							# Area info
							case surface_description.area_type
							when 'polyline'
								description[:points] = surface_description.area_info['points']
							else
								next
							end

							# Description info
							description[:description] = { type: surface_description.description_type }
							case surface_description.description_type
							when 'real_estate'
								description[:description][:id] = surface_description.real_estate_description.real_estate_id
								description[:description][:description] = surface_description.real_estate_description.real_estate.short_label || surface_description.real_estate_description.real_estate.label

								# Detect position
								if @re.id == surface_description.real_estate_description.real_estate_id
									description[:status] = 'highlight'
								end
							when 'text_image'
								description[:description][:data] = {}
								if surface_description.text_description.present?
									description[:description][:description] = surface_description.text_description.description
								end

								# if surface_description.image_descriptions.present?
								# 	image_data = []
								# 	surface_description.image_descriptions.each do |data|
								# 		image_data << { id: data.id, url: data.image.url, description: data.description, is_avatar: data.is_avatar }
								# 	end
								# 	description[:description][:data][:images] = image_data.to_json
								# end
							end

							image[:descriptions] << description
						end
					end

					images << image
				
				# / Surface

				# Group image
				
					@re.block_group.images.each do |real_estate_group_image|
						image = {}

						# Get url for display
						image[:id] = real_estate_group_image.id
						image[:url] = real_estate_group_image.image.url
						image[:thumb_url] = real_estate_group_image.image.url('thumb')

						if real_estate_group_image.image_descriptions.present?
							image[:descriptions] = []

							real_estate_group_image.image_descriptions.each do |image_description|
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
								when 'text_image'
									description[:description][:data] = {}
									if image_description.text_description.present?
										description[:description][:data][:description] = image_description.text_description.description
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
				
				# / Group image

			# / Images

			# Info

				info = render_to_string(partial: 'real_estates/info_for_interact_view')

			# / Info

			# Navigator
			
				navigator = {
					block: {
						id: @re.block.id,
						name: @re.block.display_name
					},
					group: {
						id: @re.block_group.id,
						name: @re.block_group.display_name
					},
					floor: {
						id: @re.block_floor.id,
						name: @re.block_floor.display_name
					},
					real_estate: {
						id: @re.id,
						name: @re.short_label
					}
				}

				if @re.block.block_type.present?
					unless @re.block.has_floor
						navigator[:display_position] = false
					end
				end
			
			# / Navigator

			render json: { 
				status: 0, 
				result: {
					images: images,
					info: info,
					navigator: navigator
				} 
			}
		end

		# Get values
		# params: id(*)(block_id)
		def get_options_for_interact_view
			res = RealEstate.where block_id: params[:id]

			options = []
			res.each do |re|
				options << {
					id: re.id,
					name: re.short_label,
					group_id: re.block_real_estate_group_id,
					floor_id: re.block_floor_id
				}
			end

			render json: { status: 0, result: options }
		end

		# Get values
		# params: id(*)(floor_real_estate_id)
		def floors_get_data_for_interact_view

			@position = FloorRealEstate.find params[:id]

			# Images

				images = []

				# Surface
				
					# Get all info of surface
					image = {}

					# Get url for display
					image[:url] = @position.real_estate.block_floor.surface.url

					if @position.real_estate.block_floor.surface_descriptions.present?
						image[:descriptions] = []

						@position.real_estate.block_floor.surface_descriptions.each do |surface_description|
							description = { tag_name: surface_description.area_type }

							# Area info
							case surface_description.area_type
							when 'polyline'
								description[:points] = surface_description.area_info['points']
							else
								next
							end

							# Description info
							description[:description] = { type: surface_description.description_type }
							case surface_description.description_type
							when 'real_estate'
								description[:description][:id] = surface_description.real_estate_description.real_estate_id
								description[:description][:description] = surface_description.real_estate_description.real_estate.short_label || surface_description.real_estate_description.real_estate.label

								# Detect position
								if @position.real_estate.id == surface_description.real_estate_description.real_estate_id
									description[:status] = 'highlight'
								end
							when 'text_image'
								description[:description][:data] = {}
								if surface_description.text_description.present?
									description[:description][:description] = surface_description.text_description.description
								end

								# if surface_description.image_descriptions.present?
								# 	image_data = []
								# 	surface_description.image_descriptions.each do |data|
								# 		image_data << { id: data.id, url: data.image.url, description: data.description, is_avatar: data.is_avatar }
								# 	end
								# 	description[:description][:data][:images] = image_data.to_json
								# end
							end

							image[:descriptions] << description
						end
					end

					images << image
				
				# / Surface

				# Group image
				
					@position.real_estate.block_group.images.each do |real_estate_group_image|
						image = {}

						# Get url for display
						image[:id] = real_estate_group_image.id
						image[:url] = real_estate_group_image.image.url
						image[:thumb_url] = real_estate_group_image.image.url('thumb')

						if real_estate_group_image.image_descriptions.present?
							image[:descriptions] = []

							real_estate_group_image.image_descriptions.each do |image_description|
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
				
				# / Group image

			# / Images

			# Info

				info = render_to_string(partial: 'real_estates/floors/info_for_interact_view')

			# / Info

			# Navigator
			
				navigator = {
					block: {
						id: @position.real_estate.block.id,
						name: @position.real_estate.block.display_name
					},
					group: {
						id: @position.real_estate.block_group.id,
						name: @position.real_estate.block_group.display_name
					},
					floor: {
						id: @position.real_estate.block_floor.id,
						name: @position.real_estate.block_floor.display_name
					},
					real_estate: {
						id: @position.real_estate.id,
						name: @position.real_estate.short_label
					},
					position: {
						id: @position.id,
						name: @position.display_name
					}
				}
			
			# / Navigator

			render json: { 
				status: 0, 
				result: {
					images: images,
					info: info,
					navigator: navigator
				} 
			}
		end

		# Get values
		# params: id(*)
		def floors_get_options_for_interact_view
			re_floors = FloorRealEstate.where real_estate_id: params[:id]

			options = []
			re_floors.each do |re_floor|
				options << {
					id: re_floor.id,
					name: re_floor.display_name
				}
			end

			render json: { status: 0, result: options }
		end

		# Get values
		# params: project_id, keyword
		def get_value_project_search
			project = Project.find params[:project_id]

			block_ids = project.blocks.map{ |block| block.id }

			re_result = RealEstate.where(block_id: block_ids, short_label: params[:keyword]).first
			if re_result.present?
				return render json: { status: 0, result: { type: 'real_estate', id: re_result.id } }
			end

			re_ids = RealEstate.where(block_id: block_ids).map{ |re| re.id }
			pos_result = FloorRealEstate.where(real_estate_id: re_ids, label: params[:keyword]).first
			if pos_result.present?
				return render json: { status: 0, result: { type: 'real_estates/floor', id: pos_result.id } }
			end

			return render json: { status: 1 }
		end

	# / Interact image

	# My list

		# View
		def my
			# Author
			authorize! :view_my, RealEstate

			@res = RealEstate.my_search_with_params interact: 'desc'

			render layout: 'layout_back'
		end

		# Partial view
		# params: keyword, page
		def _my_list
			# Author
			authorize! :view_my, RealEstate

			per = Rails.application.config.item_per_page

			params[:page] ||= 1
			params[:page] = params[:page].to_i

			res = RealEstate.my_search_with_params params

			count = res.count

			return render json: { status: 1 } if count == 0

			render json: {
				status: 0,
				result: {
					list: render_to_string(partial: 'real_estates/my_list', locals: { res: res.page(params[:page], per) }),
					pagination: render_to_string(partial: 'shared/pagination', locals: { total: count, per: per, page: params[:page] })
				}
			}
		end

		def change_show_status
			RealEstate.update_show_status params[:id], params[:is_show]

			render json: Hash[status: 0]
		end

		def set_owner_info
			RealEstate.set_owner_info params[:owner_info]

			render json: { status: 0 }
		end

	# / My list

	# My favorite list

		# View
		def my_favorite
			# Author
			authorize! :view_my, RealEstate

			@res = RealEstate.my_favorite_search_with_params interact: 'desc'

			render layout: 'layout_back'
		end

		# Partial view
		# params: keyword, page
		def _my_favorite_list
			# Author
			authorize! :view_my, RealEstate

			per = Rails.application.config.item_per_page

			params[:page] ||= 1
			params[:page] = params[:page].to_i

			res = RealEstate.my_favorite_search_with_params params

			count = res.count

			return render json: { status: 1 } if count === 0

			render json: {
				status: 0,
				result: {
					list: render_to_string(partial: 'real_estates/my_favorite_list', locals: { res: res.page(params[:page], per) }),
					pagination: render_to_string(partial: 'shared/pagination', locals: { total: count, per: per, page: params[:page] })
				}
			}
		end

	# / My favorite list

	# Pending

		# View
		def pending
			# Author
			authorize! :manage, RealEstate

			@res = RealEstate.pending_search_with_params interact: 'desc'

			render layout: 'layout_back'
		end

		# Partial view
		# params: keyword
		def _pending_list
			# Author
			authorize! :manage, RealEstate

			per = Rails.application.config.item_per_page
			
			params[:page] ||= 1
			params[:page] = params[:page].to_i

			res = RealEstate.pending_search_with_params params

			count = res.count

			return render json: { status: 1 } if count == 0

			render json: {
				status: 0,
				result: {
					list: render_to_string(partial: 'real_estates/pending_list', locals: { res: res.page(params[:page], per) }),
					pagination: render_to_string(partial: 'shared/pagination', locals: { total: count, per: per, page: params[:page] })
				}
			}
		end

		# Handle
		# params: id(*)
		def approve
			result = RealEstate.update_pending_status params[:id], 0

			if result[:status] == 0
				# Log
				Log.create(
					object_type: 'real_estate',
					object_id: params[:id],
					action: 'approve',
					user_type: current_user_type,
					user_id: current_user_id
				)

				Notification.create_new(
					object_type: 'real_estate',
					object_id: params[:id],
					action: 'approve',
					user_type: current_user_type,
					user_id: current_user_id
				)
			end

			render json: result

		end

	# / Pending

	# Manager

		# View
		def manager
			# Author
			authorize! :manage, RealEstate

			@res = RealEstate.manager_search_with_params interact: 'desc'

			render layout: 'layout_back'
		end

		# Partial view
		# params: keyword, page
		def _manager_list
			# Author
			authorize! :manage, RealEstate

			per = Rails.application.config.item_per_page

			params[:page] ||= 1
			params[:page] = params[:page].to_i

			res = RealEstate.manager_search_with_params params

			count = res.count

			return render json: { status: 1 } if count == 0

			render json: {
				status: 0,
				result: {
					list: render_to_string(partial: 'real_estates/manager_list', locals: { res: res.page(params[:page], per) }),
					pagination: render_to_string(partial: 'shared/pagination', locals: { total: count, per: per, page: params[:page] })
				}
			}
		end

		# Handle
		# params: id, is_force_hide
		def change_force_hide_status
			RealEstate.update_force_hide_status params[:id], params[:is_force_hide]

			render json: { status: 0 }
		end


		# Handle
		# params: id, is_favorite
		def change_favorite_status
			RealEstate.update_favorite_status params[:id], params[:is_favorite]

			render json: { status: 0 }
		end

	# / Manager

	# Appraise

		# View
		def appraise
			# Author
			return render json: { staus: 6 } if cannot? :appraise, RealEstate

			@res = RealEstate.where('appraisal_type <> 0 AND appraisal_price IS NULL').order(updated_at: 'asc')

			render layout: 'layout_back'
		end

		# Partial view
		def _appraise_list
			# Author
			return render json: { staus: 6 } if cannot? :appraise, RealEstate

			per = Rails.application.config.item_per_page

			if params[:keyword].blank?
				res = RealEstate.where('appraisal_type <> 0 AND appraisal_price IS NULL').order(updated_at: 'asc')
			else
				res = RealEstate.where('appraisal_type <> 0 AND appraisal_price IS NULL').search(params[:keyword])
			end

			count = res.count

			return render json: { status: 1 } if count == 0

			render json: {
				status: 0,
				result: {
					list: render_to_string(partial: 'real_estates/appraise_list', locals: { res: res.page(params[:page].to_i, per) }),
					pagination: render_to_string(partial: 'shared/pagination', locals: { total: count, per: per })
				}
			}
		end

		# Handle
		# params: id(*), ac_id(*)
		def set_appraisal_company
			result = AppraisalCompaniesRealEstate.assign params[:id], params[:ac_id]

			if result[:status] != 0
				render json: result
			else
				render json: { status: 0 }
			end
		end

	# / Appraise

	# Request manage
	
		# View
		def requests_manage
			# Author
			authorize! :manage, RealEstate

			@requests = ContactRequest.real_estate_contact.need_contact

			render layout: 'layout_back'
		end

		# Partial view
		# params: page
		def _requests_manage_list
			# Author
			authorize! :manage, RealEstate

			requests = ContactRequest.real_estate_contact.need_contact

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
			authorize! :manage, RealEstate

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
			result = RealEstate.delete_by_id(params[:id])

			respond_to do |format|
				format.html { redirect_to '/' }
				format.json { render json: result }
			end
		end

	# / Delete

	# Search

		# Partial view
		# params: 
		# 	type
		#   per, page, price(x;y), real_estate_type, is_full, district
		#   newest, cheapest
		def search
			res = RealEstate.search_with_params params
			
			params[:per] ||= Rails.application.config.real_estate_item_per_page
			params[:per] = params[:per].to_i

			params[:type] ||= 1

			params[:page] ||= 1
			params[:page] = params[:page].to_i
			
			return render json: { status: 1 } if res.count == 0

			render json: {
				status: 0,
				result: {
					list: render_to_string(partial: 'real_estates/item_list', locals: { res: res.page(params[:page], params[:per]), type: params[:type] }),
					pagination: render_to_string(partial: 'shared/pagination_2', locals: { total: res.count, per: params[:per], page: params[:page] })
				}
			}
		end

	# / Search

	# Gallery

		# Handle
		# params: id
		def get_gallery
			images = RealEstateImage.where(real_estate_id: params[:id]).reorder('"order" asc')

			render json: { status: 0, result: images.map { |image| { id: image.id, small: image.image.url(:thumb), original: image.image.url, description: image.description } } }
		end

	# / Gallery

	# Favorite

		# Handle
		# params: id, is_add
		def user_favorite
			if params[:is_add] == '1'
				render json: UsersFavoriteRealEstate.add_favorite(params[:id])
			else
				render json: UsersFavoriteRealEstate.remove_favorite(params[:id])
			end
		end

	# / Favorite

	# Zoho
	
		def zoho_sync

			RealEstate.zoho_sync

			render text: 'OK'

		end
	
	# / Zoho

	# Registraion
	
		# View
		def register
			@registration = ReRegistration.new

			if request.post?
				if @registration.save_with_params params[:re_registration]
					response = {
						status: 0,
						result: @registration.id
					}
				else
					response = {
						status: 2
					}
				end

				return render json: response
			end
			
			render layout: 'layout_back'
		end
	
	# / Registraion

end
