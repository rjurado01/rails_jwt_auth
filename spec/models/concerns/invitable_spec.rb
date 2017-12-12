require 'rails_helper'

describe RailsJwtAuth::Invitable do
  %w[ActiveRecord Mongoid].each do |orm|
    let(:invited_user) { "#{orm}User".constantize.invite! email: 'valid@example.com' }

    context "Using #{orm}" do
      before :all do
        RailsJwtAuth.model_name = "#{orm}User"
      end

      before :each do
        ActionMailer::Base.deliveries.clear
      end

      describe '#attributes' do
        subject { invited_user }
        it { is_expected.to have_attributes(invitation_token: invited_user.invitation_token) }
        it { is_expected.to have_attributes(invitation_accepted_at: nil) }
        it { is_expected.to have_attributes(invitation_created_at: invited_user.invitation_created_at) }

        it 'has a random password' do
          expect(subject).to_not have_attributes(password_digest: nil)
        end
      end

      describe '.invite!' do # Class method
        context 'without existing user' do
          subject { "#{orm}User".constantize.invite! email: "another@example.com" }
          it 'creates a record' do
            expect { subject }.to change { "#{orm}User".constantize.count }.by 1
          end

          it 'sends the invitation mail' do
            subject
            expect(ActionMailer::Base.deliveries.count.zero?).to be false
          end

          context 'with more fields than only email' do
            subject do
              RailsJwtAuth.model.invite!(email: "valid@example.com", name: "TestName")
            end

            it 'has extra attributes assigned' do
              expect(subject.name).to eq("TestName")
            end
          end
        end

        context 'without auth_field' do
          it 'raises exception' do
            expect { "#{orm}User".constantize.invite! }.to raise_error(ArgumentError)
          end
        end

        context 'with existing user' do
          context 'with pending invitation' do
            let(:user) { FactoryGirl.create "#{orm.underscore}_user", email: 'valid@example.com' }

            it 'doesn\'t change the users password' do
              expect(user.password_digest).to eq(user.reload.password_digest)
            end

            it 'generates invitation' do
              user = "#{orm}User".constantize.invite! email: "test@example.com"

              Timecop.freeze(Date.today + 30.days) do
                "#{orm}User".constantize.invite! email: user.email
                expect(user.reload.invitation_created_at).to eq(Time.now.utc)
              end

              expect(user.reload.invitation_created_at).to_not eq(Time.now.utc)

            end

            it 'sends the invitation mail' do
              user = "#{orm}User".constantize.invite! email: "test@example.com"
              expect(ActionMailer::Base.deliveries.count.zero?).to be false
            end
          end

          context 'when completely registered' do
            let(:user) { FactoryGirl.create "#{orm.underscore}_user", email: 'valid@example.com' }

            subject { "#{orm}User".constantize.invite! email: user.email }

            it 'has taken error on auth_field_name' do
              field = RailsJwtAuth.auth_field_name.to_sym
              error = subject.errors.details[field].first.values.first
              expect(error).to eq(:taken)
            end
          end
        end
      end

      describe '#accept_invitation!' do
        context 'with invited user' do
          before do
            Timecop.freeze
            invited_user.accept_invitation!
          end

          after do
            Timecop.return
          end

          it 'clears invitation_token' do
            expect(invited_user.invitation_token).to be_nil
          end

          it 'sets invitation_accepted_at' do
            expect(invited_user.invitation_accepted_at).to eq(Time.now.utc)
          end
        end

        context 'with non-invited user' do
          let(:user) { FactoryGirl.create "#{orm.underscore}_user" }
          before do
            user.accept_invitation!
          end

          it 'doesn\'t set invitation_accepted_at' do
            expect(user.reload.invitation_accepted_at).to be_nil
          end
        end
      end

      describe '#invite!' do
        let(:user) { FactoryGirl.build "#{orm.underscore}_user" }

        context 'without invitation token' do
          it 'generates invitation_token' do
            user.invite!
            expect(user.invitation_token).to_not be_nil
          end
        end

        context 'with token' do
          before do
            user.invitation_token = "abcde"
            user.invite!
          end

          it 'doesn\'t change actual token' do
            expect(user.invitation_token).to eq("abcde")
          end
        end

        it 'delivers invitation' do
          expect(user).to receive(:deliver_invitation)
          # expect(RailsJwtAuth::Mailer).to receive(:send_invitation)
          user.invite!
        end
      end
    end
  end
end
