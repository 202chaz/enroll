__invalid_form__ = 'A form field is missing or invalid.'

$(document).ready(function() {
  __is_safari__ = navigator.userAgent.match(/Safari/i) && !navigator.userAgent.match(/Chrome/i)
});

function ineligible_incarcerated(){
  return $('input[name="person[is_incarcerated]"]:checked').val() == 1
}

function is_citizen(){
  return $('input[name="person[us_citizen]"]:checked').val() == 'true'
}

function ineligible_immigration(){
  if (!is_citizen()) {
    immigration_ok = $('input[name="person[eligible_immigration_status]"]:checked').val() == 'true'
  }
  return !is_citizen() && !immigration_ok
}
function ineligible_alert(){
      var name = $('#person_first_name').val()
      var gender = $('input[name="person[gender]"]:checked').val()
      var pronoun = gender == 'male' ? 'he' : 'she'
      var not_citizen = " is not a citizen and does not have an eligible immigration status, "
      var not_free = " is currently incarcerated, "
      var beginning = ineligible_incarcerated() ? not_free : not_citizen
      var ending = " is not eligible to purchase a plan on DC Health Link. Other family members may still be eligible to enroll. Please call us at 1-855-532-5465 to learn about other health insurance options for "
      alert("Since " + name + beginning + pronoun + ending + name + '.')
}

$(document).on('click', '.consumer_roles #btn-continue', function(){
  var valid_form = $('form')[0].checkValidity()
  if (!valid_form) {
    if (__is_safari__) alert(__invalid_form__)
  }
  else {
    if (ineligible_immigration() || ineligible_incarcerated())  ineligible_alert()
  }
  return true
})