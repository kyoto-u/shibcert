# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

ready = ->
   $("#accordion").accordion
     collapsible: true
     active: 2

$(document).on('turbolinks:load', ready)

$('#cert_vlan_true').click ->
  if $(this).prop('checked') == true
    $('#cert_vlan_id').removeAttr 'disabled'
  else
    $('#cert_vlan_id').attr 'disabled', 'disabled'
  return

$('#cert_vlan_false').click ->
  if $(this).prop('checked') == true
    $('#cert_vlan_id').attr 'disabled', 'disabled'
  else
    $('#cert_vlan_id').removeAttr 'disabled'
  return


