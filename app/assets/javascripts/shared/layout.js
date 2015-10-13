var $body, $window, _temp = {};
var $document = $(document);

$(function () {
  $body = $('body');
  $window = $(window);

  _temp['pagination_count'] = 0;
  initSize();
  _startPagination();

  setInterval(function () {
    $.ajax({
      url: 'nothing',
      method: 'POST'
    })
  }, 870000)
});

/*
  Helper
*/

function isMobile() {
  return /Android|webOS|iPhone|iPad|iPod|BlackBerry|BB10|IEMobile|Opera Mini|Touch/i.test(navigator.userAgent);
}

/*
  / Helper
*/

/*
  Size
*/

function initSize() {
  _temp['resizing'] = null;
  $window.on('resize', function () {
    clearTimeout(_temp['resizing']);
    _temp['resizing'] = setTimeout(function () {
      var width = $(window).width(), widthType, oldWidthType = $body.data('width');

      if (width >= 1200) {
        widthType = 'lg';
      }
      else if (width >= 992) {
        widthType = 'md';
      }
      else if (width >= 768) {
        widthType = 'sm';
      }
      else {
        widthType = 'xs';
      }

      if (widthType == oldWidthType) {
        return;
      }

      $body.data('width', widthType);
      $.ajax({
        url: '/set_width/' + widthType,
        method: 'POST'
      });
    }, 500);
  });

  $window.isWidthType = function (arrayType) {
    return arrayType.indexOf($body.data('width')) != -1;
  }
}

/*
  / Size
*/

/*
  Pagination
*/

/*
  url(*)
  data
    data pass to url
    {} or function return {}
  list
    list to display
  pagination
    pagination display
  page(1)
    page display
  done
    handle after load success
    function(content, note)
  fail
    handle after load empty or fail
    function()
  return find(findParams)
    findParams:
      url
      data
        data pass to find
      note
*/

function _initPagination(params) {
  // Check if have not params or url
  if (typeof params === 'undefined' || typeof params.url === 'undefined') {
    return;
  }

  var 
    no = _temp['pagination_count']++
    keyFind = 'is_finding_' + no;

  _temp[keyFind] = false;

  var lastData = { page: params['page'] || 1 };

  // Find function
  var find = function (findParams) {
    if (typeof findParams == 'undefined') {
      findParams = {};
    }

    /*
      Get data
    */

    // data of params
    var data;
    if ('data' in params) {
      if (typeof params.data == 'function') {
        data = params.data();
      }
      else {
        data = params.data;
      }
    }
    if (typeof data != 'object') {
      data = {}
    }
    data['page'] = data['page'] || 1;

    // data of find params

    if ('data' in findParams) {
      $.extend(data, findParams['data']);
    }

    lastData = data;

    /*
      / Get data
    */

    if (_temp[keyFind]) {
      _temp[keyFind].abort();
    }

    // Get url
    var url = findParams['url'] || params['url'];

    _temp[keyFind] = $.ajax({
        url: url,
        data: data,
        dataType: 'JSON'
    }).always(function () {
      _temp[keyFind] = false;
    }).done(function (data) {
      if (data.status == 0) {
        // callback afterLoad or replace list
        if ('done' in params) {
          params['done'](data.result.list, findParams.note);
        }
        else {
          if ('list' in params) {
            params['list'].html(data.result.list); 

            if ('init_list' in params) {
              params['init_list'](params['list']); 
            }
          }
        }

        // replace pagination
        if ('pagination' in params) {
          params['pagination'].html(data.result.pagination);
          initPagination(); 
        }
      }
      else {
        if ('fail' in params) {
          params['fail'](findParams.note);
        }
        // empty pagination
        if ('pagination' in params) {
          params['pagination'].empty();
        }
        // empty list
        if ('list' in params) {
          params['list'].html('<div class="alert alert-warning alert-dismissible" style="width: 80%; margin: 0 auto;"><button type="button" class="close" data-dismiss="alert" aria-hidden="true">×</button><h4 class="no-margin"><i class="icon fa fa-warning"></i> Không tìm thấy kết quả</h4></div>')
        }
      }
    }).fail(function (xhr, status) {
      if (status != 'abort') {
        if ('fail' in params) {
          params['fail'](findParams.note);
        }
        // empty pagination
        if ('pagination' in params) {
          params['pagination'].empty();
        }
        // empty list
        if ('list' in params) {
          params['list'].html('<div class="alert alert-warning alert-dismissible" style="width: 80%; margin: 0 auto;"><button type="button" class="close" data-dismiss="alert" aria-hidden="true">×</button><h4 class="no-margin"><i class="icon fa fa-warning"></i> Không tìm thấy kết quả</h4></div>')
        }
      }
    });
  }

  if ('pagination' in params) {
    function initPagination(page) {
      params['pagination'].find('[aria-click="paging"]').on('click', function () {
        lastData['page'] = $(this).data('page');
        find({ data: lastData });
      });

      params['pagination'].find('[aria-click="prev-page"]').on('click', function () {
        lastData['page'] = lastData['page'] - 1;
        find({ data: lastData });
      });

      params['pagination'].find('[aria-click="next-page"]').on('click', function () {
        lastData['page'] = lastData['page'] + 1;
        find({ data: lastData });
      });
    }
    initPagination(params['page'] || 1);
  }

  return find;
}

/*
  aria-pagination
  data:
    url
    list
    pagination
    page
    done
    fail
    data
*/
function _startPagination() {
  $('[aria-pagination]').each(function () {
    var 
      $pagination = $(this),
      params = {};

    if ($pagination.data('url')) {
      params['url'] = $pagination.data('url');
    }

    if ($pagination.data('list')) {
      params['list'] = $($pagination.data('list'));
    }

    if ($pagination.data('pagination')) {
      params['pagination'] = $($pagination.data('pagination'));
    }

    if ($pagination.data('page')) {
      params['page'] = $($pagination.data('page'));
    }

    if ($pagination.data('done') && typeof window[$pagination.data('done')] == 'function') {
      params['done'] = window[$pagination.data('done')];
    }

    if ($pagination.data('fail') && typeof window[$pagination.data('fail')] == 'function') {
      params['fail'] = window[$pagination.data('fail')];
    }

    if ($pagination.data('data')) {
      data = $pagination.data('data');

      if (typeof data == 'object') {
        params['data'] = data;
      }
      else if (typeof window[data] == 'function') {
        params['data'] = window[data];
      }
    }

    if ($pagination.data('init_list')) {
      params['init_list'] = new Function('$list', $pagination.data('init_list'));
    }

    _initPagination(params);
  })
}

/*
  / Pagination
*/

/*
  Read money
*/

function read_money (number) {
  var is_prev_block_empty = true;
  
  /*
    Read number
  */

  function read_number(position) {
    var p = position % 3

    if (p == 0 && !is_prev_block_empty && parseInt(number.substring(position + 1, number.length)) == 0) {
      switch (number[position]) {
        case '1':
          return ['mốt '];
          break;
        case '2':
          return ['hai '];
          break;
        case '3':
          return ['ba '];
          break;
        case '4':
          return ['tư '];
          break;
        case '5':
          return ['rưỡi '];
          break;
        case '6':
          return ['sáu '];
          break;
        case '7':
          return ['bảy '];
          break;
        case '8':
          return ['tám '];
          break;
        case '9':
          return ['chín '];
          break;
      }
    }

    switch (number[position]) {
      case '0':
        if (p == 1 && number[position + 1] != '0' && parseInt(number.substring(0, position)) != 0) {
          return 'lẻ ';
        }
        break;
      case '1':
        switch (p) {
          case 0:
            return 'một trăm ';
            break;
          case 1:
            return 'mười ';
            break;
          case 2:
            if (parseInt(number[position - 1]) > 1) {
              return 'mốt '; 
            }
            else {
              return 'một ';
            }
            break;
        }
      case '2':
        switch (p) {
          case 0:
            return 'hai trăm ';
            break;
          case 1:
            return 'hai mươi ';
            break;
          default:
            return 'hai ';
            break;
        }
        break;
      case '3':
        switch (p) {
          case 0:
            return 'ba trăm ';
            break;
          case 1:
            return 'ba mươi ';
            break;
          default:
            return 'ba ';
            break;
        }
        break;
      case '4':
        switch (p) {
          case 0:
            return 'bốn trăm ';
            break;
          case 1:
            return 'bốn mươi ';
            break;
          default:
            return 'bốn ';
            break;
        }
        break;
      case '5':
        switch (p) {
          case 0:
            return 'năm trăm ';
            break;
          case 1:
            return 'năm mươi ';
            break;
          default:
            if (number[position - 1] == 0) {
              return 'năm ';
            }
            else {
              return 'lăm ';
            }
            break;
        }
        break;
      case '6':
        switch (p) {
          case 0:
            return 'sáu trăm ';
            break;
          case 1:
            return 'sáu mươi ';
            break;
          default:
            return 'sáu ';
            break;
        }
        break;
      case '7':
        switch (p) {
          case 0:
            return 'bảy trăm ';
            break;
          case 1:
            return 'bảy mươi ';
            break;
          default:
            return 'bảy ';
            break;
        }
        break;
      case '8':
        switch (p) {
          case 0:
            return 'tám trăm ';
            break;
          case 1:
            return 'tám mươi ';
            break;
          default:
            return 'tám ';
            break;
        }
        break;
      case '9':
        switch (p) {
          case 0:
            return 'chín trăm ';
            break;
          case 1:
            return 'chín mươi ';
            break;
          default:
            return 'chín ';
            break;
        }
        break;
    }

    return '';
  }
  
  /*
    / Read number
  */

  /*
    Read block
  */

  function read_block(block) {
    var text = ''
    var position = block * 3

    var noNumBefore = true;
    for (i = position; i < position + 3; i++) {
      // var t = read_number(i);

      // if (typeof t == 'object') {
      //   return t;
      // }
      // else {
      //   text += t;
      // }
      if (!(number[i] == '0' && noNumBefore)) {
        text += number[i];
        noNumBefore = false;
      }
    }

    if (text != '') {
      text += ' ';
    }
    return text;
  }

  /*
    / Read block
  */

  // Get array number (string)
  number = number.toString();
  if (number.length % 3 != 0) {
    var padLeft = new Array(3 - number.length % 3);
    for (var i = padLeft.length - 1; i >= 0; i--) { padLeft[i] = '0'; }

    number = padLeft.join('') + number;
  }

  var read_unit = ['nghìn ', 'triệu ', 'tỷ '];

  var text = '';
  var block_count = number.length / 3;

  for (var block = 0; block < block_count; block++) {
    var reverse_index = block_count - block - 1;

    var t = read_block(block);

    if (typeof t == 'object') {
      text += t[0];

      if (block_count - block > 3) {
        var d = parseInt(reverse_index / 3);
        for (var i = 0; i < d; i++) {
          text += 'tỷ ';
        }
      }
      break;
    }

    if (t != '') {
      is_prev_block_empty = false;

      text += t;
      if (block != block_count - 1) {
        text += read_unit[(reverse_index - 1) % 3];
      }
    }
    else {
      if (reverse_index > 0 && reverse_index % 3 == 0) {
        is_prev_block_empty = false;
        text += 'tỷ ';
      }
      else {
        is_prev_block_empty = true;
      }
    }
  }

  if (text != '') {
    text = text.substring(0, text.length - 1);
    text = text.charAt(0).toUpperCase() + text.substring(1);
  }

  return text;
}

/*
  / Read money
*/