class ShortUrlRequestsController < ApplicationController
  before_filter :authorise_as_short_url_requester!, only: [:new, :create]
  before_filter :authorise_as_short_url_manager!, only: [:index, :show, :accept, :new_rejection, :reject, :list_short_urls, :edit, :update]
  before_filter :get_short_url_request, only: [:edit, :update, :show, :accept, :new_rejection, :reject]

  def index
    @short_url_requests = ShortUrlRequest.pending.order_by([:created_at, 'desc']).paginate(page: (params[:page]), per_page: 40)
  end

  def show
    @existing_redirect = Redirect.where(from_path: @short_url_request.from_path).first
  end

  def list_short_urls
    @accepted_short_urls = ShortUrlRequest.all.where(state: 'accepted').order_by([:created_at, 'desc'])
  end

  def new
    @short_url_request = ShortUrlRequest.new(organisation_slug: current_user.organisation_slug)
  end

  def create
    ShortUrlRequestsService.create(
      create_short_url_request_params,
      current_user,
      success: -> (short_url_request) {
        flash[:success] = "Your request has been made."
        redirect_to root_path
      },
      failure: -> (short_url_request) {
        @short_url_request = short_url_request
        render 'new'
      },
      confirmation_required: -> (short_url_request) {
        @short_url_request = short_url_request
        render 'confirmation'
      }
    )
  end

  def accept
    ShortUrlRequestsService.accept!(
      @short_url_request,
      failure: -> () { render 'short_url_requests/accept_failed' }
    )
  end

  def new_rejection
  end

  def reject
    rejection_params = params.require(:short_url_request).permit(:rejection_reason)
    ShortUrlRequestsService.reject!(@short_url_request, rejection_params[:rejection_reason])
    flash[:success] = "The short URL request has been rejected, and the requester has been notified."

    redirect_to short_url_requests_path
  end

  def edit
  end

  def update
    ShortUrlRequestsService.update(
      @short_url_request,
      update_short_url_request_params,
      success: -> () {
        flash[:success] = "Your edit was successful."
        redirect_to short_url_request_path(@short_url_request)
      },
      failure: -> () { render 'edit' }
    )
  end

  def organisations
    @organisations ||= Organisation.all.order_by([:title, 'asc'])
  end
  helper_method :organisations

private
  def get_short_url_request
    @short_url_request = ShortUrlRequest.find(params[:id])
  rescue Mongoid::Errors::DocumentNotFound
    render text: "Not found", status: 404
  end

  def create_short_url_request_params
    params[:short_url_request].permit(:from_path, :to_path, :reason, :organisation_slug, :confirmed)
  end

  def update_short_url_request_params
    params[:short_url_request].permit(:to_path, :reason, :organisation_slug)
  end
end
