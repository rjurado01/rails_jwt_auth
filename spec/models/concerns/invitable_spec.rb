require 'rails_helper'

describe RailsJwtAuth::Invitable do
  %w[ActiveRecord Mongoid].each do |orm|
    context "Using #{orm}" do
      before(:all) { initialize_orm(orm) }
      before(:each) { ActionMailer::Base.deliveries.clear }

      let(:pass) { 'new_password' }
      let(:email) { 'valid@email.com' }
      let(:username) { 'TestName' }
      let(:invited_user) { RailsJwtAuth.model.invite email: email, username: username }
      let(:user) { FactoryBot.create "#{orm.underscore}_user", email: email }

      describe '#attributes' do
        it { expect(user).to respond_to(:invitation_token) }
        it { expect(user).to respond_to(:invitation_sent_at) }
        it { expect(user).to respond_to(:invitation_accepted_at) }
      end

      describe '.invite' do # Class method
        context 'when auth field is blank' do
          it 'returns record with auth field error' do
            user = RailsJwtAuth.model.invite
            expect(get_record_error(user, :email)).to eq(:blank)
          end
        end

        context 'when is new valid user' do
          it 'creates a record' do
            expect { invited_user }.to change { RailsJwtAuth.model.count }.by 1
          end

          it 'sends the invitation mail' do
            expect(RailsJwtAuth).to receive(:send_email).with(:invitation_instructions, anything)
            invited_user
          end

          it 'assign attributes' do
            expect(invited_user.username).to eq('TestName')
          end

          it 'returns new record' do
            expect(invited_user.class).to eq(RailsJwtAuth.model)
          end
        end

        context 'when user already exists' do
          context 'with pending invitation' do
            it 'resets invitation' do
              first_invitation_date = Time.current
              second_invitation_date = nil

              travel_to(first_invitation_date) do
                invited_user
              end

              travel_to(Time.current + 30.days) do
                RailsJwtAuth.model.invite email: invited_user.email
                second_invitation_date = Time.current.to_i
              end

              expect(first_invitation_date).not_to eq(second_invitation_date)
              expect(invited_user.reload.invitation_sent_at.to_i).to eq(second_invitation_date)
            end

            it 'sends new invitation mail' do
              invited_user
              expect(ActionMailer::Base.deliveries.count).to eq(1)
            end
          end

          context 'with register completed' do
            before { user }

            it 'returns record with registered error' do
              expect(RailsJwtAuth.model.find_by(email: user.email)).not_to be_nil
              expect(get_record_error(invited_user, :email)).to eq(:registered)
            end
          end
        end
      end

      describe '#invite' do
        context 'when user is new' do
          before do
            @user = FactoryBot.build("#{orm.underscore}_user_without_password")
            @user.invite
          end

          it 'fill in invitation fields' do
            expect(@user.invitation_token).to_not be_nil
            expect(@user.invitation_sent_at).to_not be_nil
            expect(@user.invitation_accepted_at).to be_nil
          end

          it 'sends new invitation mail' do
            expect(ActionMailer::Base.deliveries.count).to eq(1)
          end
        end

        context 'when user has pending invitation' do
          it 'resets invitation' do
            first_invitation_date = Time.current
            second_invitation_date = nil

            travel_to(first_invitation_date) do
              invited_user
            end

            travel_to(Time.current + 30.days) do
              invited_user.invite
              second_invitation_date = Time.current.to_i
            end

            expect(first_invitation_date).not_to eq(second_invitation_date)
            expect(invited_user.reload.invitation_sent_at.to_i).to eq(second_invitation_date)
          end

          it 'sends new invitation mail' do
            invited_user
            expect(ActionMailer::Base.deliveries.count).to eq(1)

            invited_user.invite
            expect(ActionMailer::Base.deliveries.count).to eq(2)
          end
        end

        context 'when user register is completed' do
          before { user }

          it 'returns record with registered error' do
            expect(RailsJwtAuth.model.find_by(email: user.email)).not_to be_nil
            user.invite
            expect(get_record_error(user, :email)).to eq(:registered)
          end
        end
      end

      describe '#accept_invitation' do
        let(:accept_attrs) { {password: pass, password_confirmation: pass} }

        context 'with invited user' do
          it 'completes invitation' do
            invited_user

            expect(invited_user.invitation_token).not_to be_nil
            expect(invited_user.invitation_sent_at).not_to be_nil
            expect(invited_user.invitation_accepted_at).to be_nil

            invited_user.accept_invitation(accept_attrs)

            expect(invited_user.invitation_token).to be_nil
            expect(invited_user.invitation_sent_at).to be_nil
            expect(invited_user.invitation_accepted_at).not_to be_nil
            expect(invited_user.confirmed_at).not_to be_nil
          end

          it 'validates password' do
            invited_user.accept_invitation({})
            expect(get_record_error(invited_user, :password)).to eq(:blank)
          end

          it 'validates token' do
            invited_user.invitation_sent_at = Time.now - 1.year
            invited_user.accept_invitation(accept_attrs)
            expect(get_record_error(invited_user, :invitation_token)).to eq(:expired)
          end

          it 'does not send password changed email' do
            invited_user
            ActionMailer::Base.deliveries.clear

            invited_user.accept_invitation(accept_attrs)
            expect(ActionMailer::Base.deliveries.count).to eq(0)
          end
        end

        context 'with non-invited user' do
          it 'doesn\'t set invitation_accepted_at' do
            expect(user.accept_invitation({})).to be_falsey
            expect(user.reload.invitation_accepted_at).to be_nil
          end
        end
      end

      describe '#valid_for_invite?' do
        it 'returns when record is valid for invite' do
          u = FactoryBot.build("#{orm.underscore}_user_without_password")
          expect(u.valid_for_invite?).to be_truthy
        end
      end
    end
  end
end
