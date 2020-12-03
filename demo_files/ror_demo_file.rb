class InvitationsController < ApplicationController

  def new
    @invitation = Invitation.new

    @invitation.invitation_type = 'SystemInvitation'

    if params[:organization_id].present?
      @invitation.organization_id = params[:organization_id]
      @invitation.role = 'member'
      @invitation.invitation_type = 'OrganizationInvitation'
    end

    if params[:sandbox_id].present?
      @invitation.sandbox_id = params[:sandbox_id]
      @invitation.invitation_type = 'SandboxInvitation'
    end

    render :new,layout: false
  end

  def create
    person = User.find_by_email(params[:invitation][:email])&.person
    params[:invitation][:person_id] = person.id if person.present?
    if params[:invitation][:organization_id].present?
      params[:invitation][:invitation_type] = 'OrganizationInvitation'
      create_system_invitation member_params unless person.present?
    else
      params[:invitation][:invitation_type] = 'SystemInvitation'
    end
    @invitation = Invitation.new(member_params)
    @invitation.save
    associate_person_to_organization person if person.present?
    flash.notice = "Invitation sent"

    if ((@invitation.organization_id.present?) &&(@invitation.organization_id== current_organization.id))
      redirect_to people_path()
    elsif params[:invitation][:organization_id].present?
      redirect_to organization_path(params[:invitation][:organization_id])
    else
      redirect_to admin_invite_index_path()
    end
  end

  def update
    @organization = Organization.find(params[:organization_id])
    @invitation = Invitation.find_by_id params[:id]
    @invitation.role = params[:membership][:role]
    @invitation.save
    redirect_to organization_path(@organization)
  end

  def resend
    @invitation = Invitation.find_by_id params[:id]
    @invitation.send_invitation

    if ((@invitation.organization_id.present?) &&(@invitation.organization_id== current_organization.id))
      redirect_to people_path()
    elsif @invitation.organization_id.present?
      redirect_to organization_path(@invitation.organization_id)
    else
      redirect_to admin_invite_index_path()
    end
  end

  def destroy
    invitation = Invitation.find params[:id]
    organization_id = invitation.organization_id
    if invitation.destroy
      flash.notice = t('invitation_deleted')
    else
      flash.notice = t('error')
    end

    if ((organization_id.present?) && (organization_id== current_organization.id))
      redirect_to people_path()
    elsif organization_id.present?
      redirect_to organization_path(organization_id)
    else
      redirect_to admin_invite_index_path()
    end
  end

  def change
  end


  private

  def member_params
    params.require(:invitation).permit(:person_id, :email, :role, :organization_id, :invitation_type, :sandbox_id)
  end

  def create_system_invitation(member_params)
    system_invitation = Invitation.new member_params
    system_invitation.invitation_type = 'SystemInvitation'
    system_invitation.save
  end

  def associate_person_to_organization(person)
    UserInitializer.new(person.user).associate_from_organization_invitations
  end
end

