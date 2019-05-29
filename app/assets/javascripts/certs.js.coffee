# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

#$("#cert_vlan_true").click ->
#    $("#cert_vlan_id").prop("disabled", false)
#    return
#
#$("#cert_vlan_false").click ->
#    $("#cert_vlan_id").prop("disabled", true)
#    return

$ -> 
  $('input[name="cert[vlan]"]').change ->
    if $("#cert_vlan_true").prop("checked")
        $("#cert_vlan_id").prop("disabled", false)
    else
        $("#cert_vlan_id").prop("disabled", true)
    return
