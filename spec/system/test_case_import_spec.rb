require 'rails_helper'

RSpec.describe "Test Case Import", type: :system do
  include PromptEngine::Engine.routes.url_helpers

  let(:prompt) { create(:prompt, name: "Greeting Prompt", content: "Hello {{name}}, you are {{age}} years old") }
  let(:eval_set) { create(:eval_set, prompt: prompt, name: "Basic Tests") }

  before do
    # Ensure parameters are synced
    prompt.sync_parameters!

    driven_by(:cuprite)
  end

  scenario "User imports test cases from CSV file" do
    # Create a temporary CSV file
    csv_content = <<~CSV
      name,age,expected_output,description
      Alice,28,Hello Alice! You are 28 years old.,Test with Alice
      Bob,35,Hello Bob! You are 35 years old.,Test with Bob
      Charlie,42,Hello Charlie! You are 42 years old.,
    CSV

    csv_file = Tempfile.new([ 'test_cases', '.csv' ])
    csv_file.write(csv_content)
    csv_file.rewind

    # Visit eval set page
    visit prompt_eval_set_path(prompt, eval_set)

    expect(page).to have_content("Basic Tests")
    expect(page).to have_content("No test cases added yet")

    # Click import button
    within(".card", text: "Test Cases") do
      click_link "Import"
    end

    expect(page).to have_content("Import Test Cases")
    expect(page).to have_content("File Format Requirements")

    # Upload file
    attach_file "file", csv_file.path
    click_button "Preview Import"

    # Preview page
    expect(page).to have_content("Import Preview")
    expect(page).to have_content("3 test cases will be imported")
    expect(page).to have_content("Test with Alice")
    expect(page).to have_content("Test with Bob")
    expect(page).to have_content("Test case #3") # No description for Charlie

    # Confirm import
    click_button "Import Test Cases"

    # Back on eval set page
    expect(page).to have_content("Successfully imported 3 test cases")
    expect(page).to have_content("Test with Alice")
    expect(page).to have_content("Test with Bob")

    # Verify test cases were created
    within(".table") do
      expect(page).to have_css("tbody tr", count: 3)
    end

    csv_file.close
    csv_file.unlink
  end

  scenario "User imports test cases from JSON file" do
    json_content = [
      {
        input_variables: { name: "David", age: "50" },
        expected_output: "Hello David! You are 50 years old.",
        description: "Senior user test"
      },
      {
        input_variables: { name: "Eve", age: "18" },
        expected_output: "Hello Eve! You are 18 years old."
      }
    ].to_json

    json_file = Tempfile.new([ 'test_cases', '.json' ])
    json_file.write(json_content)
    json_file.rewind

    visit prompt_eval_set_path(prompt, eval_set)

    within(".card", text: "Test Cases") do
      click_link "Import"
    end

    attach_file "file", json_file.path
    click_button "Preview Import"

    expect(page).to have_content("2 test cases will be imported")
    expect(page).to have_content("Senior user test")

    click_button "Import Test Cases"

    expect(page).to have_content("Successfully imported 2 test cases")

    json_file.close
    json_file.unlink
  end

  scenario "User sees error for invalid file format" do
    visit prompt_eval_set_path(prompt, eval_set)

    within(".card", text: "Test Cases") do
      click_link "Import"
    end

    # Try to upload a text file
    txt_file = Tempfile.new([ 'invalid', '.txt' ])
    txt_file.write("This is not CSV or JSON")
    txt_file.rewind

    attach_file "file", txt_file.path
    click_button "Preview Import"

    expect(page).to have_content("Unsupported file format")

    txt_file.close
    txt_file.unlink
  end

  scenario "User cancels import at preview stage" do
    csv_content = "name,age,expected_output\nTest,20,Output"
    csv_file = Tempfile.new([ 'test', '.csv' ])
    csv_file.write(csv_content)
    csv_file.rewind

    visit import_prompt_eval_set_test_cases_path(prompt, eval_set)

    attach_file "file", csv_file.path
    click_button "Preview Import"

    expect(page).to have_content("Import Preview")

    click_link "Cancel"

    expect(current_path).to eq(prompt_eval_set_path(prompt, eval_set))
    expect(page).to have_content("No test cases added yet")

    csv_file.close
    csv_file.unlink
  end
end
