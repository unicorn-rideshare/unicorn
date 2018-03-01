class ReadonlyValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, _value)
    changed = record.send("#{attribute}_changed?")
    record.errors.add(attribute, :readonly) if changed
  end
end
