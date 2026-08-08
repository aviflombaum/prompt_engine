require "rails_helper"

RSpec.describe PromptEngine do
  describe "configure" do
    it "yields the configuration object" do
      PromptEngine.configure do |config|
        config.options_for_model_select = [
          ["Custom Model 1", "custom-model-1"]
        ]
      end

      expect(
        PromptEngine.configuration.options_for_model_select
      ).to eq([["Custom Model 1", "custom-model-1"]])
    end
  end
end
