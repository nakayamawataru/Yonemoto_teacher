class EndAtDatetimeValidator < ActiveModel::EachValidator
  def validate_each record, attribute, value
    return unless value
    record.errors.add attribute, :end_at_datetime if less_or_equal_than_start_at?(record, value)
  end

  private

  def less_or_equal_than_start_at? record, value
    return true unless record.start_at
    value <= record.start_at
  end
end
