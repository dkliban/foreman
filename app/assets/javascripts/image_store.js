function providerSelected(item)
{
  var provider = $(item).val();
  if(provider == "") {
    $("[type=submit]").attr("disabled",true);
    return false;
  }
  $("[type=submit]").attr("disabled",false);
  var url = $(item).attr('data-url');
  var data = 'provider=' + provider;
  $('#compute_connection').load(url + ' div#compute_connection', data);
}
