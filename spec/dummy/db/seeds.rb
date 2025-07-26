# Create sample prompts for testing
puts "Seeding database..."

# Clear existing data
PromptEngine::Prompt.destroy_all

# Create sample prompts
prompt1 = PromptEngine::Prompt.new
prompt1.name = "Customer Support Response"
prompt1.description = "Generates helpful customer support responses"
prompt1.content = "Please provide a helpful and empathetic response to the following customer inquiry: {{customer_message}}"
prompt1.system_message = "You are a helpful customer support agent. Be professional, empathetic, and solution-oriented."
prompt1.model = "gpt-4"
prompt1.temperature = 0.7
prompt1.max_tokens = 500
prompt1.status = "active"
prompt1.save!

prompt2 = PromptEngine::Prompt.new
prompt2.name = "Product Description Writer"
prompt2.description = "Creates engaging product descriptions"
prompt2.content = "Write an engaging product description for: {{product_name}}. Key features: {{features}}"
prompt2.model = "gpt-3.5-turbo"
prompt2.temperature = 0.8
prompt2.max_tokens = 300
prompt2.status = "active"
prompt2.save!

prompt3 = PromptEngine::Prompt.new
prompt3.name = "Email Subject Line Generator"
prompt3.description = "Generates catchy email subject lines"
prompt3.content = "Generate 5 compelling email subject lines for: {{email_topic}}"
prompt3.model = "claude-3-haiku"
prompt3.temperature = 0.9
prompt3.max_tokens = 150
prompt3.status = "draft"
prompt3.save!

puts "Created #{PromptEngine::Prompt.count} sample prompts!"

# Create evaluation sets and test cases
puts "Creating evaluation sets and test cases..."

# Eval set for Customer Support Response
eval_set1 = PromptEngine::EvalSet.create!(
  prompt: prompt1,
  name: "Customer Support Quality Check",
  description: "Tests various customer support scenarios for quality and empathy"
)

# Add test cases for customer support
PromptEngine::TestCase.create!(
  eval_set: eval_set1,
  input_variables: {
    customer_message: "My order hasn't arrived and it's been 2 weeks!"
  },
  expected_output: "I sincerely apologize for the delay with your order. I understand how frustrating this must be after waiting for two weeks. Let me immediately look into this for you and find out exactly where your package is. Could you please provide me with your order number so I can track it down right away?",
  description: "Delayed order complaint"
)

PromptEngine::TestCase.create!(
  eval_set: eval_set1,
  input_variables: {
    customer_message: "The product I received is defective"
  },
  expected_output: "I'm very sorry to hear that you received a defective product. This is certainly not the experience we want you to have. I'd be happy to help you resolve this immediately. We can either send you a replacement right away or process a full refund - whichever you prefer. Could you please describe the defect so I can also report this to our quality team?",
  description: "Defective product complaint"
)

PromptEngine::TestCase.create!(
  eval_set: eval_set1,
  input_variables: {
    customer_message: "I'm very happy with my purchase! Thank you!"
  },
  expected_output: "Thank you so much for taking the time to share your positive feedback! It's wonderful to hear that you're happy with your purchase. We truly appreciate customers like you. If you need anything else or have any questions in the future, please don't hesitate to reach out. Have a great day!",
  description: "Positive feedback"
)

# Eval set for Product Description Writer
eval_set2 = PromptEngine::EvalSet.create!(
  prompt: prompt2,
  name: "Product Description Quality",
  description: "Tests product description generation for different product types"
)

# Add test cases for product descriptions
PromptEngine::TestCase.create!(
  eval_set: eval_set2,
  input_variables: {
    product_name: "Wireless Bluetooth Headphones",
    features: "Noise cancellation, 30-hour battery, comfortable fit"
  },
  expected_output: "Experience premium audio freedom with our Wireless Bluetooth Headphones. Featuring advanced noise cancellation technology, you'll immerse yourself in crystal-clear sound while blocking out distractions. The impressive 30-hour battery life keeps your music playing all day and beyond. Designed with comfort in mind, these headphones provide a perfect fit for extended listening sessions.",
  description: "Electronics product"
)

PromptEngine::TestCase.create!(
  eval_set: eval_set2,
  input_variables: {
    product_name: "Organic Green Tea",
    features: "Antioxidant-rich, hand-picked, sustainable farming"
  },
  expected_output: "Discover the pure essence of wellness with our Organic Green Tea. Each leaf is carefully hand-picked from sustainable farms, ensuring the highest quality and environmental responsibility. Packed with powerful antioxidants, this premium tea supports your health while delighting your senses with its delicate, refreshing flavor.",
  description: "Food & beverage product"
)

# Create a sample completed eval run
completed_run = PromptEngine::EvalRun.create!(
  eval_set: eval_set1,
  prompt_version: prompt1.versions.first,
  status: "completed",
  started_at: 10.minutes.ago,
  completed_at: 5.minutes.ago,
  total_count: 3,
  passed_count: 2,
  failed_count: 1,
  openai_run_id: "run_sample_123",
  report_url: "https://platform.openai.com/evals/sample"
)

puts "Created #{PromptEngine::EvalSet.count} evaluation sets"
puts "Created #{PromptEngine::TestCase.count} test cases"
puts "Created #{PromptEngine::EvalRun.count} sample eval runs"

# Load cost configurations
load Rails.root.join("../../db/seeds/cost_configs.rb")
