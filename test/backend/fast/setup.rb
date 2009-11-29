# encoding: utf-8

module Tests
  module Backend
    module Fast
      module Setup
        module Base
          include Tests::Backend::Simple::Setup::Base

          def setup
            I18n.backend = I18n::Backend::Fast.new
            super
          end
        end

        module Localization
          include Base
          include Tests::Backend::Simple::Setup::Localization
        end
      end
    end
  end
end