class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value =~ RailsJwtAuth.email_regex
      record.errors.add(attribute, (options[:message] || 'invalid'))
    end
  end
end
