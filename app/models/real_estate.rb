class RealEstate < ActiveRecord::Base

  include PgSearch
  pg_search_scope :search, against: {
    meta_search_1: 'A',
    meta_search_2: 'B',
    meta_search_3: 'C'
  }, using: { tsearch: { prefix: true, any_word: true } }

  serialize :params, JSON

# Associates

  belongs_to :user
  belongs_to :real_estate_type
  belongs_to :street
  belongs_to :ward
  belongs_to :district
  belongs_to :province
  belongs_to :currency
  belongs_to :purpose
  belongs_to :sell_unit, class_name: 'Unit'
  belongs_to :rent_unit, class_name: 'Unit'
  belongs_to :legal_record_type
  belongs_to :planning_status_type
  belongs_to :constructional_level
  belongs_to :direction

  has_many :images, -> { order('is_avatar desc') }, class_name: 'RealEstateImage'
  has_many :appraisal_companies_real_estates
  has_many :appraisal_companies, through: :appraisal_companies_real_estates
  has_many :assigned_appraisal_companies, -> { where('appraisal_companies_real_estates.is_assigned' => true) }, through: :appraisal_companies_real_estates,
            source: :appraisal_company,
            class_name: 'AppraisalCompany'

  has_and_belongs_to_many :property_utilities
  has_and_belongs_to_many :region_utilities
  has_and_belongs_to_many :advantages
  has_and_belongs_to_many :disadvantages
  
# / Associates

# Validates

  validate :custom_validate

  def custom_validate
    # Purpose
    if fields.include?(:purpose) && purpose.blank?
      errors.add :purpose, 'Mục đích không thể bỏ trống'
      return
    end

    # Currency
    if fields.include?(:currency) && currency.blank?
      errors.add :currency, 'Loại tiền tệ không thể bỏ trống'
      return
    end

    # Unit
    if fields.include?(:sell_unit) && sell_unit.blank?
      errors.add :sell_unit, 'Đơn vị tính giá bán không thể bỏ trống'
      return
    end
    if fields.include?(:rent_unit) && rent_unit.blank?
      errors.add :rent_unit, 'Đơn vị tính giá cho thuê không thể bỏ trống'
      return
    end

    # Location
    if fields.include?(:province) && province.blank?
      errors.add :province, 'Tỉnh/thành phố không thể bỏ trống'
      return
    end
    if fields.include?(:district) && district.blank?
      errors.add :district, 'Quận không thể bỏ trống'
      return
    end
    if fields.include?(:street) && street.blank?
      errors.add :street, 'Đường không thể bỏ trống'
      return
    end

    # Street_type
    if fields.include?(:street_type) && street_type.blank?
      errors.add :street_type, 'Loại đường không thể bỏ trống'
      return
    end

    # Alley
    if fields.include?(:is_alley) && is_alley.nil?
      errors.add :is_alley, 'Mặt đường không thể bỏ trống'
      return
    end
    if fields.include?(:alley_width) && alley_width.blank?
      errors.add :alley_width, 'Độ rộng hẻm không thể bỏ trống'
      return
    end

    # Type
    if fields.include?(:real_estate_type) && real_estate_type.blank?
      errors.add :real_estate_type, 'Loại bất động sản không thể bỏ trống'
      return
    end

    # Building name
    if fields.include?(:building_name) && building_name.blank?
      errors.add :building_name, 'Tên tòa nhà không thể bỏ trống'
      return
    end

    # Area
    if fields.include?(:constructional_area) && constructional_area.blank?
      errors.add :constructional_area, 'Diện tích xây dựng không thể bỏ trống'
      return
    end
    if fields.include?(:using_area) && using_area.blank?
      errors.add :using_area, 'Diện tích sử dụng không thể bỏ trống'
      return
    end
    if fields.include?(:campus_area) && campus_area.blank?
      errors.add :campus_area, 'Diện tích khuôn viên không thể bỏ trống'
      return
    end

    # Width
    # if fields.include?(:width_x) && width_x.blank?
    #   errors.add :width_x, 'Chiều ngang không thể bỏ trống'
    #   return
    # end
    # if fields.include?(:width_y) && width_y.blank?
    #   errors.add :width_y, 'Chiều dài không thể bỏ trống'
    #   return
    # end

    # Shape
    if fields.include?(:shape) && shape.blank?
      errors.add :shape, 'Hình dáng không thể bỏ trống'
      return
    end
    if fields.include?(:shape_width) && shape_width.blank?
      errors.add :shape_width, 'Kích thước mặt hậu không thể bỏ trống'
      return
    end

    # Number of ...
    # if fields.include?(:floor_number) && floor_number.blank?
    #   errors.add :floor_number, 'Tầng không thể bỏ trống'
    #   return
    # end
    if fields.include?(:restroom_number) && restroom_number.blank?
      errors.add :restroom_number, 'Số phòng tắm không thể bỏ trống'
      return
    end
    if fields.include?(:bedroom_number) && bedroom_number.blank?
      errors.add :bedroom_number, 'Số phòng ngủ không thể bỏ trống'
      return
    end

    # Direction
    if fields.include?(:direction) && direction.blank?
      errors.add :direction, 'Hướng không thể bỏ trống'
      return
    end

    # Constructional level
    if fields.include?(:constructional_level) && constructional_level.blank?
      errors.add :constructional_level, 'Loại nhà không thể bỏ trống'
      return
    end

    # Build year
    if fields.include?(:build_year) && build_year.blank?
      errors.add :build_year, 'Năm xây dựng không thể bỏ trống'
      return
    end

    # Constructional level
    if fields.include?(:constructional_level) && constructional_level.blank?
      errors.add :constructional_leval, 'Loại nhà không thể bỏ trống'
      return
    end


    # Constructional quality
    if fields.include?(:constructional_quality) && constructional_quality.blank?
      errors.add :constructional_quality, 'Hiện trạng không thể bỏ trống'
      return
    end

    # Title
    if fields.include?(:title) && title.blank?
      errors.add :title, 'Tiêu đề không thể bỏ trống'
      return
    end

    # Description
    if fields.include?(:description) && description.blank?
      errors.add :description, 'Mô tả không thể bỏ trống'
      return
    end

    # Legal record type
    if fields.include?(:legal_record_type)
      if legal_record_type.blank? && legal_record_type_id != 0
        errors.add :legal_record_type, 'Hồ sơ pháp lý không thể bỏ trống'
        return
      end
      if fields.include?(:custom_legal_record_type) && custom_legal_record_type.blank?
        errors.add :custom_legal_record_type, 'Hồ sơ pháp lý không thể bỏ trống'
        return
      end
    end

    # Planning status type
    if fields.include?(:planning_status_type)
      if planning_status_type.blank? && planning_status_type_id != 0
        errors.add :planning_status_type, 'Tình trạng quy hoạch không thể bỏ trống'
        return
      end
      if fields.include?(:custom_planning_status_type) && custom_planning_status_type.blank?
        errors.add :custom_planning_status_type, 'Tình trạng quy hoạch không thể bỏ trống'
        return
      end
    end

    # User contact
    if user_id == 0
      if user_full_name.blank?
        errors.add :user_full_name, 'Họ tên liên lạc không thể bỏ trống'
        return
      end
      if user_email.blank?
        errors.add :user_email, 'Email liên lạc không thể bỏ trống'
        return
      end
    end
  end

# / Validates

# Insert

  # Get params

  def assign_attributes_with_params params
    # Get price
    if params.has_key? :sell_price
      params[:sell_price] = ApplicationHelper.format_i params[:sell_price]
      params[:sell_price_text] = ApplicationHelper.read_money params[:sell_price]
    end
    if params.has_key? :rent_price
      params[:rent_price] = ApplicationHelper.format_i(params[:rent_price])
      params[:rent_price_text] = ApplicationHelper.read_money params[:rent_price]
    end

    # Alley width
    params[:alley_width] = ApplicationHelper.format_f params[:alley_width] if params.has_key? :alley_width

    # Area
    params[:constructional_area] = ApplicationHelper.format_f params[:constructional_area] if params.has_key? :constructional_area
    params[:using_area] = ApplicationHelper.format_f params[:using_area] if params.has_key? :using_area
    params[:campus_area] = ApplicationHelper.format_f params[:campus_area] if params.has_key? :campus_area
    params[:width_x] = ApplicationHelper.format_f params[:width_x] if params.has_key? :width_x
    params[:width_y] = ApplicationHelper.format_f params[:width_y] if params.has_key? :width_y

    # Location
    if params[:province].present?
      if params[:province] == 'Hồ Chí Minh'
        params[:province] = 'Tp. Hồ Chí Minh'
      end
      province = Province.find_or_create_by name: params[:province]
      params[:province_id] = province.id
    end
    unless params[:district].blank?
      district = District.find_or_create_by name: params[:district], province_id: params[:province_id]
      params[:district_id] = district.id
    end
    unless params[:ward].blank?
      ward = Ward.find_or_create_by name: params[:ward]
      params[:ward_id] = ward.id
    end
    unless params[:street].blank?
      street = Street.find_or_create_by name: params[:street]
      params[:street_id] = street.id
    end

    # Advantages, disavantage, property utility, region utility
    params[:advantage_ids] = [] unless params.has_key? :advantage_ids
    params[:disadvantage_ids] = [] unless params.has_key? :disadvantage_ids
    params[:property_utility_ids] = [] unless params.has_key? :property_utility_ids
    params[:region_utility_ids] = [] unless params.has_key? :region_utility_ids

    # Images

    _images = []
    _has_avatar = false
    if params[:image_ids].present?
      params[:image_ids].each do |_v|
        _value = JSON.parse _v

        if _value['is_new']
          TemporaryFile.get_file(_value['id']) do |_image, _id|
            _images << RealEstateImage.new(image: _image, is_avatar: _value['is_avatar'], description: _value['description'])

            _has_avatar = true if _value['is_avatar']
          end
        else
          _image = RealEstateImage.find _value['id']
          _image.description = _value['description']
          _image.is_avatar = _value['is_avatar']
          _image.save if _image.changed?          

          _has_avatar = true if _value['is_avatar']

          _images << _image
        end
      end
    end
    if !_has_avatar && _images.length != 0
      _images[0].assign_attributes is_avatar: true
    end
    assign_attributes images: _images

    assign_attributes params.permit [
      :title, :description, :purpose_id, :sell_price, :sell_price_text, :rent_price, :rent_price_text, 
      :currency_id, :sell_unit_id, :rent_unit_id, :is_negotiable, :province_id, :district_id, :ward_id, :street_id, 
      :address_number, :street_type, :is_alley, :real_estate_type_id, :building_name,
      :legal_record_type_id, :planning_status_type_id, :custom_advantages, :custom_disadvantages,
      :alley_width, :shape_width, :custom_legal_record_type, :custom_planning_status_type, :is_draft,
      :lat, :long, :user_id, :appraisal_purpose, :appraisal_type, :campus_area, :using_area, :constructional_area,
      :shape, :shape_width, :bedroom_number, :build_year, :constructional_level_id, :restroom_number,
      :width_x, :width_y, :floor_number, :constructional_quality, :direction_id,
      advantage_ids: [], disadvantage_ids: [], property_utility_ids: [], region_utility_ids: []
    ]
  end

  # Save with params

  def save_with_params params, is_draft = false
    # Author
    return { status: 6 } if is_draft == true && !User.signed?
    if new_record?
      return { status: 6 } if User.current.cannot? :create, RealEstate
    else
      return { status: 6 } if User.current.cannot? :edit, self
    end

    assign_attributes_with_params params

    other_params = {
      is_draft: is_draft,
      is_full: params[:is_full],
      is_pending: true
    }

    if user_id == 0
      other_params = other_params.merge params.permit(:user_full_name, :user_phone_number)
      other_params[:params] = { 'remote_ip' => params[:remote_ip] }

      if new_record?
        other_params[:user_email] = params[:user_email]
        other_params[:is_active] = false
        other_params[:params]['secure_code'] = SecureRandom.base64
      end
    end

    assign_attributes other_params

    assign_meta_search

    if save validate: !is_draft
      { status: 0 }
    else 
      { status: 3, result: errors.full_messages }
    end
  end

  # / Save with params

# / Insert

# Get

  # Get by current purpose

  def self.get_by_current_purpose
    purpose_condition = nil

    case User.options[:current_purpose]
    when 'r'
      purpose_condition = 'purposes.code = \'rent\' OR purposes.code = \'sell_rent\''
    else
      purpose_condition = 'purposes.code = \'sell\' OR purposes.code = \'sell_rent\''
    end
    joins(:purpose).where(purpose_condition)
  end

  # / Get by current purpose

  # Get random

  def self.get_random
    order('RANDOM()')
  end

  # / Get random

  # Search with params

  # params: 
  #   keyword, price(x;y), real_estate_type, is_full, district
  #   is_favorite
  #   newest, cheapest
  def self.search_with_params params = {}
    where = 'is_pending = false AND is_show = true AND is_force_hide = false'
    joins = []
    order = {}

    if params.has_key? :price
      price_range = params[:price].split(';')

      if User.options[:current_purpose] == 'r'
        where += " AND rent_price IS NOT NULL AND rent_price BETWEEN #{price_range[0]} AND #{price_range[1]}"
      else
        where += " AND sell_price IS NOT NULL AND sell_price BETWEEN #{price_range[0]} AND #{price_range[1]}"
      end
    end

    if params.has_key? :real_estate_type
      joins << :real_estate_type
      where += " AND real_estate_types.code LIKE '%|#{params[:real_estate_type]}|%'"
    end

    if params.has_key? :district
      joins << :district
      where += " AND districts.id = #{params[:district]} "
    end

    if params.has_key? :is_favorite
      where += " AND is_favorite = #{params[:is_favorite]}"
    end

    if params.has_key? :keyword
      search params[:keyword]
    end

    if params.has_key?(:cheapest) || params.has_key?(:price)
      if User.options[:current_purpose] == 'r'
        order[:rent_price] = 'asc'
      else
        order[:sell_price] = 'asc'
      end
    end

    if params.has_key? :newest
      order[:created_at] = 'asc'
    end

    where += " AND is_full = #{params[:is_full] || 'true'}"

    joins(joins).get_by_current_purpose.where(where).order(order)
  end

  # params: 
  #   keyword,
  #   newest, cheapest, interact, view, id, favorite
  def self.my_search_with_params params = {}
    where = "user_id = #{User.current.id}"
    joins = []
    order = {}

    if params.has_key? :view
      order[:view_count] = params[:view]
    end

    if params.has_key? :interact
      order[:updated_at] = params[:interact]
    end

    if params.has_key? :favorite
      order[:is_favorite] = params[:favorite]
    end

    if params.has_key? :id
      order[:id] = params[:id]
    end

    if params[:keyword].present?
      search(params[:keyword]).joins(joins).where(where).order(order)
    else
      joins(joins).where(where).order(order)
    end
  end

  # params: 
  #   keyword,
  #   newest, cheapest, interact, view, id, favorite
  def self.pending_search_with_params params = {}
    where = 'is_pending = true AND is_draft = false AND is_active = true'
    joins = []
    order = {}

    if params.has_key? :view
      order[:view_count] = params[:view]
    end

    if params.has_key? :interact
      order[:updated_at] = params[:interact]
    end

    if params.has_key? :favorite
      order[:is_favorite] = params[:favorite]
    end

    if params.has_key? :id
      order[:id] = params[:id]
    end

    if params[:keyword].present?
      search(params[:keyword]).joins(joins).where(where).order(order)
    else
      joins(joins).where(where).order(order)
    end
  end

  # params: 
  #   keyword,
  #   newest, cheapest, interact, view, id, favorite
  def self.manager_search_with_params params = {}
    where = 'is_pending = false'
    joins = []
    order = {}

    if params.has_key? :view
      order[:view_count] = params[:view]
    end

    if params.has_key? :interact
      order[:updated_at] = params[:interact]
    end

    if params.has_key? :favorite
      order[:is_favorite] = params[:favorite]
    end

    if params.has_key? :id
      order[:id] = params[:id]
    end

    if params[:keyword].present?
      search(params[:keyword]).joins(joins).where(where).order(order)
    else
      joins(joins).where(where).order(order)
    end
  end

  # / Search with params

# / Get

# Updates

  # Update show status

  def self.update_show_status id, is_show
    real_estate = find id

    # Author
    return { status: 6 } if User.current.cannot? :change_show_status, real_estate

    real_estate.is_show = is_show

    if real_estate.save validate: false
      { status: 0 }
    else
      { status: 2 }
    end
  end

  # / Update show status

  # Update force hide status

  def self.update_force_hide_status id, is_force_hide
    real_estate = find id

    # Author
    return { status: 6 } if User.current.cannot? :change_force_hide_status, real_estate

    real_estate.is_force_hide = is_force_hide

    if real_estate.save validate: false
      { status: 0 }
    else
      { status: 2 }
    end
  end

  # / Update force hide status

  # Update favorite status

  def self.update_favorite_status id, is_favorite
    real_estate = find id

    # Author
    return { status: 6 } if User.current.cannot? :change_favorite_status, real_estate

    real_estate.is_favorite = is_favorite

    if real_estate.save validate: false
      { status: 0 }
    else
      { status: 2 }
    end
  end

  # / Update favorite status

  # Update pending status

  def self.update_pending_status id, is_pending
    # Author
    return { status: 6 } if User.current.cannot? :approve, RealEstate

    real_estate = find id

    real_estate.is_pending = is_pending

    if real_estate.save validate: false
      { status: 0 }
    else
      { status: 2 }
    end
  end

  # / Update pending status

  # Active

  def self.active id, secure_code
    re = find id

    return { status: 1 } if re.is_active

    return { status: 0, result: 1 } if re.params['secure_code'] != secure_code

    re.is_active = true
    re.save
    { status: 0, result: 0 }
  end

  # / Active

# / Update

# Helper

  # Get fields

  def self.get_fields re
    fields = [
      :purpose, :currency, :is_negotiable,
      :address_number, :province, :district, :ward, :street, :lat, :long,
      :title, :description]#, :image]

    if re.purpose.present?
      fields << :sell_price << :sell_unit if re.purpose.code == 'sell' || re.purpose.code == 'sell_rent'
      fields << :rent_price << :rent_unit if re.purpose.code == 'rent' || re.purpose.code == 'sell_rent'
    end

    if re.is_full
      fields << :street_type << :is_alley
      fields << :alley_width if re.is_alley
      fields << :real_estate_type << :region_utility << :advantage << :disadvantage

      if re.purpose.code == 'sell' || re.purpose.code == 'sell_rent'
        fields << :legal_record_type << :planning_status_type
        fields << :custom_legal_record_type if re.legal_record_type_id == 0
        fields << :custom_planning_status_type if re.planning_status_type_id == 0
      end

      case re.real_estate_type.options_hash['group']
        when 'land'
          fields << :campus_area << :shape << :width_x << :width_y
        when 'space', 'house'
          fields << :campus_area << :using_area << :constructional_area << :restroom_number << :bedroom_number << :build_year <<
            :constructional_level << :constructional_quality << :direction << :shape << :width_x << :width_y << :property_utility
          if re.real_estate_type.options_hash['group'] == 'house'
            fields << :floor_number
            if re.real_estate_type.name == 'villa'
              fields.delete :constructional_level
            end
          end
          if re.real_estate_type.name == 'office'
            fields << :building_name
          end
        when 'apartment'
          fields << :building_name << :using_area << :floor_number << :bedroom_number << :restroom_number <<
            :build_year << :constructional_quality << :direction << :property_utility
      end
    else
      fields << :real_estate_type << :campus_area
    end

    fields
  end

  # / Get fields

  # Get meta search

  def assign_meta_search
    tempLocale = I18n.locale
    I18n.locale = 'vi'

    assign_attributes meta_search_1: "#{display_id} #{id} #{district.name if district.present?} #{street.name if street.present?} #{I18n.t('real_estate_type.text.' + real_estate_type.name) if real_estate_type.present?}", meta_search_2: "#{I18n.t('real_estate.attribute.' + (is_alley ? 'alley' : 'facade'))} #{title} #{I18n.t('purpose.text.' + purpose.name) if purpose.present?} #{province.name if province.present?}", meta_search_3: "#{user_id == 0 ? user_full_name + ' ' + user_email + ' ' + user_phone_number : user.full_name + ' ' + user.email + ' ' + user.phone_number} #{ward.name if ward.present?}"

    I18n.locale = tempLocale
  end

  # / Get meta search

# / Helper

# Delete
  
  def self.delete_by_id id
    real_estate = find id

    return { status: 1 } if real_estate.nil?

    # Author
    return { status: 6 } if User.current.cannot? :delete, real_estate

    if delete id
      { status: 0 }
    else
      { status: 2 }
    end
  end

# / Delete

# Attributes

  # Fields
  def fields
    @fields ||= RealEstate.get_fields self
  end

  # Name
  def name
    @name ||= "#{I18n.t('purpose.text.' + purpose.name) unless purpose.nil?} #{I18n.t('real_estate_type.text.' + real_estate_type.name) unless real_estate_type.nil?} - #{I18n.t('real_estate.attribute.' + (is_alley ? 'alley' : 'facade'))} #{street.name unless street.nil?} #{district.name unless district.nil?} #{province.name unless province.nil?}."
  end

  # ID
  def display_id
    @id ||= ApplicationHelper.id_format id, 'RE'
  end

  # Full address
  def display_address
    @display_address ||= "#{address_number} #{street.name unless street.nil?}#{', ' + ward.name unless ward.nil?}#{', ' + district.name unless district.nil?}#{', ' + province.name unless province.nil?}".gsub(/\b\w/) { $&.capitalize }
  end

  # Real estate type
  def display_real_estate_type
    @display_real_estate_type ||= I18n.t 'real_estate_type.text.' + real_estate_type.name unless real_estate_type.nil?
  end

  # Restroom
  def display_restroom
    @display_restroom ||= restroom_number == 4 ? 'Hơn 4' : restroom_number
  end

  # Bedroom
  def display_bedroom
    @display_bedroom ||= bedroom_number == 4 ? 'Hơn 4' : bedroom_number
  end

  # Area
  def display_area
    @display_area ||= fields.include?(:campus_area) ? campus_area : (fields.include?(:constructional_area) ? constructional_area : using_area) 
  end

  # Purpose
  def display_purpose
    @display_purpose ||= (I18n.t 'purpose.text.' + purpose.name if purpose.present?)
  end

  # Sell price
  def display_sell_price
    @display_sell_price_text ||= (sell_price_text.blank? ? 'Giá thỏa thuận' : sell_price_text + (currency.code != 'VND' ? ' ' + currency.name : '') + I18n.t('unit.text.display_' + sell_unit.name)).html_safe
  end

  # Rent price
  def display_rent_price
    @display_rent_price_text ||= (rent_price_text.blank? ? 'Giá thỏa thuận' : rent_price_text + (currency.code != 'VND' ? ' ' + currency.name : '') + I18n.t('unit.text.display_' + rent_unit.name)).html_safe
  end

  # Price
  def display_price
    if User.options[:current_purpose] == 'r'
      display_rent_price
    else
      display_sell_price
    end
  end

  # Legal record type
  def display_legal_record_type
    @display_legal_record_type ||= (fields.include?(:custom_legal_record_type) ? custom_legal_record_type : (I18n.t 'legal_record_type.text.' + legal_record_type.name) if fields.include? :legal_record_type)
  end

  # Planning status type
  def display_planning_status_type
    @display_planning_status_type ||= (fields.include?(:custom_planning_status_type) ? custom_planning_status_type : (I18n.t 'planning_status_type.text.' + planning_status_type.name) if fields.include? :planning_status_type)
  end

  # Constructional quality
  def get_constructional_quality
    case constructional_quality
      when 1
        'Đang xuống cấp'
      when 2
        'Còn sử dụng tốt'
      when 3
        'Mới'
      else
        'Rất mới'
    end
  end
  def display_constructional_quality
    @display_constructional_quality ||= get_constructional_quality
  end

# / Attributes



  # Get keyword

  def keyword
    legal = legal_record_type_id == 0 ? legal_record_type.name : custom_legal_record_type
    alley = is_alley == 1 ? 'Hẻm' : 'Mặt tiền'

    keyword =  
      "#{name}, #{purpose.name} #{real_estate_type.name} quận #{district.name}, #{real_estate_type.name} #{legal}, #{real_estate_type.name} #{alley}, #{alley} quận #{district.name}, #{street.name} quận #{district.name}, #{purpose.name}, #{province.name}, #{real_estate_type.name}, #{legal}"
  end

  # / Get keyword

end