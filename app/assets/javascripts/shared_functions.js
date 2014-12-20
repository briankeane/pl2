$(document).ready(function() {
  // addToMyStationButton -- on dj_booth and stations#show
  $(document).on('click', '.addToMyStationButton', function() {
    if (!$(this).hasClass('disabled')) {
      var songId = parseInt($(this).attr('data-songId'));
      createSpinPerWeekListItem({ id: songId,
                    spinFrequency: 'Medium' });
      $(this).addClass('disabled');
      $(this).text('Song Added');
    }
  });
});