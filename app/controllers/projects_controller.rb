class ProjectsController < ApplicationController
  layout 'layout_front'

# Index

  # View
  def index
    @projects = Project.where(is_draft: 0, is_show: 1).limit(6)
  end

def demo
end

# / Index

# View

  # View
  # params: id(*)
  def view
    @project = Project.find params[:id]

    session[:project_viewed] ||= []
    unless session[:project_viewed].include? params[:id]
      @project.update(view_count: @project.view_count + 1)
      session[:project_viewed] << params[:id]
    end
  end

# / View

# Create

  # View
  # params: id
  def create
    if params.has_key? :id
      begin
        @p = Project.find params[:id]
      rescue
        @p = Project.new
      end
    else
      @p = Project.new
    end
    
    # Author
    if @p.new_record?
      authorize! :create, Project
    else
      authorize! :edit, @p
    end

  	render layout: 'layout_back'
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
        return render json: Hash[status: 1]
      end
    end

    result = project.save_with_params(params[:project], is_draft)

    return render json: result if result[:status] != 0

    render json: { status: 0, result: project.id }
  end

  # View
  def create_details
    render layout: 'layout_back'
  end

# / Create

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
    return render json: { status: 6 } if cannot? :view_my, Project

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
    authorize! :view_my_favorite, Project

    @projects = Project.my_favorite_search_with_params interact: 'desc'

    render layout: 'layout_back'
  end

  # Partial view
  # params: keyword, page
  def _my_favorite_list
    # Author
    return render json: { status: 6 } if cannot? :view_my_favorite, Project

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
    return render json: { status: 6 } if cannot? :manage, Project

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
    images = ProjectImage.where project_id: params[:id]

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
