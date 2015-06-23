$(function() {
  $('div[name=broker_signup_primary_tabs] > ').children().each( function() { 
    $(this).change(function(){
      filter = $(this).val();
      $('#' + filter + '_panel').siblings().empty().hide();
      $('#' + filter + '_panel').show();
      $.ajax({
        url: '/broker_roles/new.js',
        type: "GET",
        data : { 'filter': filter }
      });
    })
  })
})

$(document).on('change', "div[name=broker_agency_tabs] input[type='radio']", function() {
  filter = 'broker_role';
  agency_type = $(this).val();
  $('#' + agency_type + '_broker_agency_form').siblings().hide();
  $('#' + agency_type + '_broker_agency_form').show();
});

$(document).on('click', '.broker-agency-search a.search', function() {
  $('.broker-agency-search .result').empty();
  var broker_agency_search = $('input#agency_search').val();
  if (broker_agency_search != undefined && broker_agency_search != ""){
    $(this).button('loading');
    $('#person_broker_agency_id').val("");
    $.ajax({
      url: '/broker_roles/search_broker_agency.js',
      type: "GET",
      data : { 'broker_agency_search': broker_agency_search }
    });
  };
});

$(document).on('click', "a.select-broker-agency", function() {
  $('.result .form-border').removeClass("agency-selected");
  $('#person_broker_agency_id').val($(this).data('broker_agency_profile_id'));
  $(this).parents(".form-border").addClass("agency-selected");
});
