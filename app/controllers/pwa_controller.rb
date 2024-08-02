class PwaController < ApplicationController
  skip_forgery_protection

  # We need a stable URL at the root, so we can't use the regular asset path here.
  def service_worker; end

  # Need ERB interpolation for paths, so can't use asset path here either.
  def manifest; end
end
