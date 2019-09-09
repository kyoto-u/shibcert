# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

ready = ->
   $("#accordion1").accordion
     collapsible: true
     active: 2
   $("#accordion2").accordion
     collapsible: true
     active: 2

$(document).on('turbolinks:load', ready)

$ -> 
  $('input[name="cert[vlan]"]').change ->
    if $("#cert_vlan_true").prop("checked")
        $("#cert_vlan_id").prop("disabled", false)
    else
        $("#cert_vlan_id").prop("disabled", true)
    return
