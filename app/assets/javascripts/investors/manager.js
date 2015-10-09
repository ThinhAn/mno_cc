$(function () {
  var 
    $list = $('#investor_list');

  initItem();
  initDelete();
  initPagination();
  initRename();

  /*
    Item
  */

  function initItem($item) {
    if ($item) {
      setItem($item);
    }
    else {
      $list.find('.item').each(function () {
        setItem($(this));
      });
    }

    function setItem($item) {

      $item.find('[aria-object="name"]').dotdotdot({
        height: 50,
        watch: true
      });

    }

  }

  /*
    / Item
  */

  /*
    Delete buttons
  */

  function initDelete() {
    $list.find('[aria-click="delete"]').on('click', function () {
      var $item = $(this).closest('.item');

      popupPrompt({
        title: _t.form.confirm_title,
        content: _t.investor.view.manager.delete_confirm,
        type: 'warning',
        buttons: [
          {
            text: _t.form.yes,
            type: 'warning',
            handle: function () {
              toggleLoadStatus(true);
              $.ajax({
                url: '/investors/delete/' + $item.data('value'),
                method: 'POST',
                contentType: 'JSON'
              }).always(function () {
                toggleLoadStatus(false);
              }).done(function (data) {
                if (data.status == 0) {
                  $item.parent().remove();
                }
                else {
                  popupPrompt({
                    title: _t.form.error_title,
                    content: _t.form.error_content,
                    type: 'danger'
                  });
                }
              }).fail(function () {
                popupPrompt({
                  title: _t.form.error_title,
                  content: _t.form.error_content,
                  type: 'danger'
                });
              });
            }
          },
          {
            text: _t.form.no
          }
        ]
      })
    });
  }

  /*
    / Delete buttons
  */

  /*
    Rename
  */

  function initRename() {
    $list.find('[aria-click="rename"]').on('click', function () {
      var 
        $button = $(this),
        $item = $button.closest('.item'),
        $html = $(_popupContent['edit_form']),
        $form = $html.find('form'),
        form = $form[0];
      
      form.elements['id'].value = $item.data('value');
      form.elements['name'].value = $item.find('[aria-object="name"]').text();
      $(form.elements['avatar_id']).attr('data-init-value', $item.attr('data-avatar'));
      var $popup = popupFull({
        html: $html
      });

      $html.find('button[type="button"]').on('click', function () {
        $popup.off();
      });

      initForm($form, {
        submit: function () {
          toggleLoadStatus(true);
          $.ajax({
            url: '/investors/rename',
            method: 'POST',
            data: $form.serialize(),
            dataType: 'JSON'
          }).always(function () {
            toggleLoadStatus(false);
          }).done(function (data) {
            if (data.status == 0) {
              $popup.off();

              $item.find('[aria-object="name"]').text(form.elements['name'].value);

              if (form.elements['avatar_id']) {
                $item.find('[aria-object="avatar"]').attr('src', data.avatar_url);
                $item.attr('data-avatar', JSON.stringify({ url: data.avatar_url }));
              }
              else {
                $item.find('[aria-object="avatar"]').attr('src', '/assets/investors/default.png');
                $item.attr('data-avatar', '');
              }
            }
            else {
              popupPrompt({
                title: _t.form.error_title,
                type: 'danger',
                content: _t.form.error_content
              });
            }
          }).fail(function () {
            popupPrompt({
              title: _t.form.error_title,
              type: 'danger',
              content: _t.form.error_content
            })
          });
        }
      });
    });
  }

  /*
    / Rename
  */

  /*
    Pagination
  */

  function initPagination() {
    find = _initPagination({
      url: '/investors/_manager_list',
      list: $list,
      pagination: $('#pagination'),
      done: function (content) {
        $list.html(content);
        initItem();
        initDelete();
        initRename();
      }
    });

    var searchForm = document.getElementById('search_form');
    initForm($(searchForm), {
      submit: function () {
        find({
          data: {
            keyword: searchForm.elements['keyword'].value
          }
        });
      }
    });
  }

  /*
    / Pagination
  */
});