# Represents any organization of the system and has an organization_info object to hold its info
class Organization < Profile  
  has_one :organization_info

  belongs_to :region

  has_one :validation_info

  after_create do |org|
      OrganizationInfo.create!(:organization_id => org.id)
  end

  def contact_email
    self.organization_info ? self.organization_info.contact_email : nil
  end

  def validation_methodology
    methodology = self.validation_info ? self.validation_info.validation_methodology : nil
    methodology || ('<em>' + _('(not informed)') + '</em>')
  end

  def validation_restrictions
    restrictions = self.validation_info ? self.validation_info.restrictions : nil
    restrictions || ('<em>' + _('(not informed)') + '</em>')
  end
end
