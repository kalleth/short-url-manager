class ShortUrlRequestsService
  def self.create(params, requester, success:, confirmation_required:, failure:)
    short_url_request = create_object(params, requester)

    if requires_confirmation?(short_url_request)
      confirmation_required.call(short_url_request)
    elsif short_url_request.save
      Notifier.short_url_requested(short_url_request).deliver_now
      success.call(short_url_request)
    else
      failure.call(short_url_request)
    end
  end

  def self.update(short_url_request, params, success:, failure:)
    if short_url_request.update_attributes(params)
      if short_url_request.redirect.present?
        short_url_request.redirect.update_attributes(
          from_path: short_url_request.from_path,
          to_path: short_url_request.to_path,
        )
      end

      success.call
    else
      failure.call
    end
  end

  def self.accept!(short_url_request, failure:)
    redirect = Redirect.find_or_initialize_by(from_path: short_url_request.from_path)

    if redirect.update_attributes(to_path: short_url_request.to_path, short_url_request: short_url_request)
      short_url_request.update_attribute(:state, 'accepted')
      Notifier.short_url_request_accepted(short_url_request).deliver_now
    else
      failure.call
    end
  end

  def self.reject!(short_url_request, reason=nil)
    short_url_request.update_attributes(state: 'rejected', rejection_reason: reason)
    Notifier.short_url_request_rejected(short_url_request).deliver_now
  end

private
  def self.create_object(params, requester)
    ShortUrlRequest.new(params).tap do |short_url_request|
      short_url_request.requester = requester
      short_url_request.contact_email = requester.email
    end
  end

  def self.requires_confirmation?(short_url_request)
    short_url_request.duplicate? && !short_url_request.confirmed
  end
end
