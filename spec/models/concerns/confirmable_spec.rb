require 'rails_helper'

describe RailsJwtAuth::Confirmable do
  %w(ActiveRecord Mongoid).each do |orm|
    let(:user) { FactoryGirl.create("#{orm.underscore}_user") }
    let(:unconfirmed_user) { FactoryGirl.create("#{orm.underscore}_unconfirmed_user") }

    context "when use #{orm}" do
      describe '#attributes' do
        it { expect(user).to have_attributes(confirmation_token: user.confirmation_token) }
        it { expect(user).to have_attributes(confirmation_sent_at: user.confirmation_sent_at) }
        it { expect(user).to have_attributes(confirmed_at: user.confirmed_at) }
      end

      describe '#confirmed?' do
        it 'returns if user is confirmed' do
          expect(user.confirmed?).to be_truthy
          expect(unconfirmed_user.confirmed?).to be_falsey
        end
      end

      describe '#confirm!' do
        it 'confirms user' do
          unconfirmed_user.confirm!
          expect(unconfirmed_user.confirmed?).to be_truthy
        end
      end

      describe '#skip_confirmation!' do
        it 'skips user confirmation after create' do
          new_user = FactoryGirl.build("#{orm.underscore}_user")
          new_user.skip_confirmation!
          new_user.save
          expect(new_user.confirmed?).to be_truthy
        end
      end

      describe '#send_confirmation_instructions' do
        before :all do
          class Mock
            def deliver
            end
          end
        end

        it 'fills confirmation fields' do
          mock = Mock.new
          new_user = FactoryGirl.create("#{orm.underscore}_unconfirmed_user")
          allow(RailsJwtAuth::Mailer).to receive(:confirmation_instructions).and_return(mock)
          new_user.send_confirmation_instructions
          expect(new_user.confirmation_token).not_to be_nil
          expect(new_user.confirmation_sent_at).not_to be_nil
        end

        it 'send confirmation email' do
          mock = Mock.new
          new_user = FactoryGirl.create("#{orm.underscore}_unconfirmed_user")
          allow(RailsJwtAuth::Mailer).to receive(:confirmation_instructions).and_return(mock)
          expect(mock).to receive(:deliver)
          new_user.send_confirmation_instructions
        end
      end

      describe '#after_create' do
        it 'send confirmation instructions' do
          new_user = FactoryGirl.build("#{orm.underscore}_user")
          expect(new_user).to receive(:send_confirmation_instructions)
          new_user.save
        end
      end
    end
  end
end
