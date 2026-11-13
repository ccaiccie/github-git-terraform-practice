# VLANs on the lab switch. The lab simulates the
# "lab_vlan" resource type; see the practice README.
resource "lab_vlan" "users" {
  vlan_id = 10
  name    = "USERS"
}

resource "lab_vlan" "voice" {
  vlan_id = 20
  name    = "VOICE"
}
