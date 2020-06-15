require 'rails_helper'

describe RailsJwtAuth do
  before(:all) { initialize_orm('ActiveRecord') }

  describe '#send_email' do
    let(:unconfirmed_user) { FactoryBot.create(:active_record_unconfirmed_user) }

    after { RailsJwtAuth.deliver_later = false }

    context 'when deliver_later options is false' do
      before { RailsJwtAuth.deliver_later = false }

      it 'uses deliver method' do
        mock2 = OpenStruct.new(deliver: true)
        mock = OpenStruct.new(confirmation_instructions: mock2)

        expect(RailsJwtAuth.mailer).to receive(:with).with(user_id: unconfirmed_user.id.to_s)
                                                     .and_return(mock)
        expect(mock2).to receive(:deliver)

        RailsJwtAuth.send_email(:confirmation_instructions, unconfirmed_user)
      end
    end

    context 'when deliver_later options is false' do
      before { RailsJwtAuth.deliver_later = true }

      it 'uses deliver method' do
        mock2 = OpenStruct.new(deliver_later: true)
        mock = OpenStruct.new(confirmation_instructions: mock2)

        expect(RailsJwtAuth.mailer).to receive(:with).with(user_id: unconfirmed_user.id.to_s)
                                                     .and_return(mock)
        expect(mock2).to receive(:deliver_later)

        RailsJwtAuth.send_email(:confirmation_instructions, unconfirmed_user)
      end
    end
  end
end
