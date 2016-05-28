Puppet::Type.newtype(:ec2_launchconfiguration) do
  @doc = 'Type representing an EC2 launch configuration.'

  ensurable

  newparam(:name, namevar: true) do
    desc 'The name of the launch configuration.'
    validate do |value|
      fail 'launch configurations must have a name' if value == ''
      fail 'name should be a String' unless value.is_a?(String)
    end
  end

  newproperty(:security_groups, :array_matching => :all) do
    desc 'The security groups to associate with the instances.'
    validate do |value|
      fail 'security_groups should be a String' unless value.is_a?(String)
      fail 'you must specify security groups for the launch configuration' if value.empty?
    end
    def insync?(is)
      is.to_set == should.to_set
    end
  end

  newparam(:user_data) do
    desc 'User data script to execute on new instances.'
  end

  newproperty(:key_name) do
    desc 'The name of the key pair associated with this instance.'
    validate do |value|
      fail 'key_name should be a String' unless value.is_a?(String)
    end
  end

  newproperty(:region) do
    desc 'The region in which to launch the instances.'
    validate do |value|
      fail 'region should not contain spaces' if value =~ /\s/
      fail 'region should not be blank' if value == ''
      fail 'region should be a String' unless value.is_a?(String)
    end
  end

  newproperty(:instance_type) do
    desc 'The type to use for the instances.'
    validate do |value|
      fail 'instance_type should not contains spaces' if value =~ /\s/
      fail 'instance_type should not be blank' if value == ''
      fail 'instance_type should be a String' unless value.is_a?(String)
    end
  end

  newproperty(:image_id) do
    desc 'The image id to use for the instances.'
    validate do |value|
      fail 'image_id should not contain spaces' if value =~ /\s/
      fail 'image_id should not be blank' if value == ''
      fail 'image_id should be a String' unless value.is_a?(String)
    end
  end

  newparam(:vpc) do
    desc 'A hint to specify the VPC, useful when detecting ambiguously named security groups like default.'
    validate do |value|
      fail 'vpc should be a String' unless value.is_a?(String)
    end
  end

  newproperty(:block_device_mappings, :array_matching => :all) do
    desc "One or more mappings that specify how block devices are exposed to the instance."
    validate do |value|
      Puppet.warning "validate(#{value})"
      devices = value.is_a?(Array) ? value : [value]
      devices.each do |device|
        fail "block device must be named" unless value.keys.include?('device_name')
        choices = ['volume_size', 'snapshot_id']
        fail "block device must include at least one of: " + choices.join(' ') if (value.keys & choices).empty?
        if value['volume_type'] == 'io1'
          fail 'must specify iops if using provisioned iops volumes' unless value.keys.include?('iops')
        end
      end
    end

    def insync?(is)
      existing_devices = is.collect { |device| device[:device_name] }
      specified_devices = should.collect { |device| device['device_name'] }
      existing_devices.to_set == specified_devices.to_set
    end

    def set(value)
      read_only_warning(value, self, should)
    end
  end

  newproperty(:associate_public_ip_address, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc 'Specifies whether to assign a public IP address to each instance launched in a Amazon VPC. If the instance is launched into a default subnet, the default is true.'
    defaultto :true
    newvalues(:true, :false)
    def insync?(is)
      is.to_s == should.to_s
    end

    def set(value)
      read_only_warning(value, self, should)
    end
  end

  autorequire(:ec2_securitygroup) do
    groups = self[:security_groups]
    groups.is_a?(Array) ? groups : [groups]
  end

  autorequire(:ec2_vpc) do
    self[:vpc]
  end

end
def read_only_warning(value, property, should)
  msg = "#{property.name} is read-only. Cannot set to: #{should}"
  Puppet.warning msg
  #raise Puppet::Error, msg
  false
end
