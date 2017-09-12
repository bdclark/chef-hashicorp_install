if defined?(ChefSpec)
  def create_hashicorp_service_systemd(res_name)
    ChefSpec::Matchers::ResourceMatcher.new(:hashicorp_service, :create, res_name)
  end

  def remove_hashicorp_service_systemd(res_name)
    ChefSpec::Matchers::ResourceMatcher.new(:hashicorp_service, :remove, res_name)
  end

  def create_hashicorp_service_sysvinit(res_name)
    ChefSpec::Matchers::ResourceMatcher.new(:hashicorp_service, :create, res_name)
  end

  def remove_hashicorp_service_sysvinit(res_name)
    ChefSpec::Matchers::ResourceMatcher.new(:hashicorp_service, :remove, res_name)
  end

  def create_hashicorp_service_upstart(res_name)
    ChefSpec::Matchers::ResourceMatcher.new(:hashicorp_service_upstart, :create, res_name)
  end

  def remove_hashicorp_service_upstart(res_name)
    ChefSpec::Matchers::ResourceMatcher.new(:hashicorp_service_upstart, :remove, res_name)
  end

  def create_hashicorp_service(res_name)
    ChefSpec::Matchers::ResourceMatcher.new(:hashicorp_service, :create, res_name)
  end

  def remove_hashicorp_service(res_name)
    ChefSpec::Matchers::ResourceMatcher.new(:hashicorp_service, :remove, res_name)
  end
end
