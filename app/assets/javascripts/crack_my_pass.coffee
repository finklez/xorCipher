# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  $('body').on 'submit', '#form-crack', (e)=>
    e.preventDefault()
    $list = $('#guesses').find('.list')
    $form = $('#form-crack')

    $list.empty()

    if !$('#encrypted_text').val().replace(/ /, '').length
      $list.html('<tr><td colspan=2><b class="error">text cannot be empty</b></td></tr>')
      return


    $list.html('<tr><td colspan=2><b class="loading">running..</b></td></tr>')

    $.post '/crack_my_pass',
      $form.serialize()
      (data) ->
        if data.error
          $list.html('<tr><td colspan=2><b class="error">Input error</b></td></tr>')
          return

        if !data.guesses.length
          $list.html('<tr><td colspan=2><b class="error">No results found :(</b></td></tr>')
          return

        guesses = $.map data.guesses, (val)->
          '<tr><td>' + val[0] + '</td><td>' + val[1] + '</td></tr>'
        .join('')
        $list.html(guesses)
