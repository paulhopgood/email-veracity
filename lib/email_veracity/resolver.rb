module EmailVeracity
  class Resolver

    RECORD_NAMES_TO_RESOLVE_MAP = {
      :a => {
        :method => 'address',
        :type => AddressServer,
        :constant => Resolv::DNS::Resource::IN::A },
      :mx => {
        :method => 'exchange',
        :type => ExchangeServer,
        :constant => Resolv::DNS::Resource::IN::MX } }

    def Resolver.get_servers_for(domain_name, record = :a)
      Timeout::timeout(Config[:timeout]) do
        get_resources_for(domain_name, record).collect do |server_name|
          type = RECORD_NAMES_TO_RESOLVE_MAP[record.to_sym][:type]
          type.new(server_name)
        end
      end
     rescue Timeout::Error
      raise DomainResourcesTimeoutError,
        "Timed out while try to resolve #{domain_name}"
    end

    protected

    def Resolver.get_resources_for(domain_name, record = :a)
      Resolv::DNS.open do |server|
        record_map = RECORD_NAMES_TO_RESOLVE_MAP[record]
        resources = server.getresources(domain_name, record_map[:constant])
        resources_to_servers(resources, record_map[:method])
      end
    end

    def Resolver.resources_to_servers(resources, resolve_method)
      resources.inject([]) do |array, resource|
        array << resource.method(resolve_method).call.to_s.strip
      end.reject_blank_items
    end

  end
end
