require 'rails_helper'

describe RailsJwtAuth::Trackable do
  %w[ActiveRecord Mongoid].each do |orm|
    let(:user) do
      FactoryBot.create(
        "#{orm.underscore}_user",
        last_sign_in_at: Time.current,
        last_sign_in_ip: '127.0.0.1'
      )
    end

    context "when use #{orm}" do
      before(:all) { RailsJwtAuth.model_name = "#{orm}User" }

      describe '#attributes' do
        it { expect(user).to have_attributes(last_sign_in_at: user.last_sign_in_at) }
        it { expect(user).to have_attributes(last_sign_in_ip: user.last_sign_in_ip) }
      end

      describe '#update_tracked_fields!' do
        before do
          class Request
            def remote_ip
            end
          end
        end

        after do
          Object.send(:remove_const, :Request)
        end

        it 'updates tracked fields and save record' do
          user = FactoryBot.create(:active_record_user)
          request = Request.new
          allow(request).to receive(:remote_ip).and_return('127.0.0.1')
          user.update_tracked_fields!(request)
          expect(user.last_sign_in_at).not_to eq(Time.current)
          expect(user.last_sign_in_ip).to eq('127.0.0.1')
        end
      end
    end
  end
end
