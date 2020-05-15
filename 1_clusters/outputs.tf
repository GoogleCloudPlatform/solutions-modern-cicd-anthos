/**
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

output "development__cluster-service-account" {
  value       = module.anthos-platform-dev.service_account
  description = "Service account used to create the cluster and node pool(s)"
}

output "staging__cluster-service-account" {
  value       = module.anthos-platform-staging.service_account
  description = "Service account used to create the cluster and node pool(s)"
}

output "prod-east__cluster-service-account" {
  value       = module.anthos-platform-prod-east.service_account
  description = "Service account used to create the cluster and node pool(s)"
}

output "prod-central__cluster-service-account" {
  value       = module.anthos-platform-prod-central.service_account
  description = "Service account used to create the cluster and node pool(s)"
}
