FactoryBot.define do
  factory :work do
    detail { Facker::Loren.characters(number:30) }
    # images { [ Rack::Test::UploadedFile.new(Rails.root.join('spec/factories/test.jpg'), 'spec/factories/test.jpg') ] }
    post
  end
end