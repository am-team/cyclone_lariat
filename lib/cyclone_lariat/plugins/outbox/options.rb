# frozen_string_literal: true

require 'luna_park/values/compound'

module CycloneLariat
  module Outbox
    class Options < LunaPark::Values::Compound
      attr_accessor :dataset, :resend_timeout, :on_sending_error
    end
  end
end
