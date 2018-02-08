guard :shell do
  watch(%r{terraform/(?:.*).tf$}) {|m| `terraform plan ./infra/terraform/environments/production` }
end
