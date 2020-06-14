require 'rails_helper'

describe RailsJwtAuth::Trackable do
  %w[ActiveRecord Mongoid].each do |orm|
    context "when use #{orm}" do
      before(:all) { initialize_orm(orm) }

      let(:user) do
        FactoryBot.create(
          "#{orm.underscore}_user",
          last_sign_in_at: Time.current,
          last_sign_in_ip: '127.0.0.1'
        )
      end

      describe '#attributes' do
        it { expect(user).to have_attributes(last_sign_in_at: user.last_sign_in_at) }
        it { expect(user).to have_attributes(last_sign_in_ip: user.last_sign_in_ip) }
      end

      describe '#track_session_info' do
        it 'fill in tracked fields' do
          user = FactoryBot.create(:active_record_user)
          request = OpenStruct.new(ip: '127.0.0.1')
          user.track_session_info(request)
          expect(user.last_sign_in_at).not_to eq(Time.current)
          expect(user.last_sign_in_ip).to eq('127.0.0.1')
          expect(user.changed?).to be_truthy
        end
      end
    end
  end
end
