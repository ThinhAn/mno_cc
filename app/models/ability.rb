class Ability

	include CanCan::Ability

	def initialize user, request
		user ||= User.new

		# General

			# User
			
				if user.new_record?
                    can :create, User
					can :login
				else
					can :logout
				end
			
			# / User
			
			# Real estate
			
				can :view, RealEstate, is_pending: false, is_show: true, is_force_hide: false
				can :create, RealEstate
				can [:view, :edit, :delete], RealEstate do |re|
					re.user_type == 'contact_user' && request[:secure_code] == re.params['secure_code']
				end
			
			# / Real estate

			# Project
			
				can :view, Project, is_pending: false, is_show: true, is_force_hide: false
			
			# / Project
		
		# / General

		return if user.new_record?

		# Sign in required

			can [:view_my, :set_my], :all

			# User
			
				can [:edit], User, id: user.id
			
			# / User

			# Real estate
			
				can [:view, :edit, :delete], RealEstate, user_type: 'user', user_id: user.id

			# / Real estate

			# Real estate favorite
			
				can :create, UsersFavoriteRealEstate
				can :delete, UsersFavoriteRealEstate, user_id: user.id
			
			# / Real estate favorite

		# / Sign in required

		# With permission

			can :manage, :all if user.is_admin

			# System group
			
				can :manage, [User, SystemGroup] if user.system_permissions.include? 1
			
			# / System group
		
			# Real estate

				can :manage, RealEstate if user.system_permissions.include? 2
			
			# / Real estate

			# Project
			
				can [:create, :edit, :delete], Project do |project|
					project.new_record? || user.represented_investors.exists?(id: project.investor_id)
				end if user.represented_investors.present?

				can :manage, Project if user.system_permissions.include? 3
			
			# / Project

			# Mail
			
				can :manage, SystemMail if user.system_permissions.include? 4
			
			# / Mail

			# Contents
			
				can :manage, ['Contents', District, Province] if user.system_permissions.include? 5
			
			# / Contents

			# Blog
			
				can :manage, Blog if user.system_permissions.include? 6
			
			# / Blog
		
		# / With permission

	end

end
