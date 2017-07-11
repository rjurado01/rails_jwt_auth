class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value =~ RailsJwtAuth.email_regex
      record.errors[attribute] << (options[:message] || I18n.t('rails_jwt_auth.errors.email.invalid'))
    end
  end
end
