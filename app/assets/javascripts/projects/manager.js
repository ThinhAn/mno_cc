$(function () {
	var $list = $('#project_list'), find;

	initItem();
	initEventButton();
	initPagination();

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

			$item.find('.address').dotdotdot({
				height: 40,
				watch: true
			});

			/*
				Status
			*/

			var 
				status = $item.data('status'),
				isForceHide = listString.has('force_hide', status),
				isFavorite = listString.has('favorite', status),
				// isAppraised = listString.has('appraised', status),
				// isNotAppraised = listString.has('not_appraised', status);
				$status = $item.find('[aria-name="status"]');

			$status.html('');

			if (isForceHide) {
				$status.append('<article class="node status-animation node-warning"><div class="text"><span>' + _t.project.attribute.hide_status + '</span></div><div class="fa fa-eye-slash"></div></article>')
			}
			else {
				$status.append('<article class="node status-animation node-primary"><div class="text"><span>' + _t.project.attribute.show_status + '</span></div><div class="fa fa-eye"></div></article>')
			}

			if (isFavorite) {
				$status.append('<article class="node status-animation node-danger"><div class="text"><span>' + _t.project.attribute.favorite_status + '</span></div><div style="top: 1px" class="fa fa-heart"></div></article>')
			}

			// Constrol buttons

			if (isForceHide) {
				$item.find('[aria-click="change-force-hide-status"]').attr('title', _t.project.view.manager.show).removeClass('fa-eye-slash').addClass('fa-eye');
			}
			else {
				$item.find('[aria-click="change-force-hide-status"]').attr('title', _t.project.view.manager.hide).removeClass('fa-eye').addClass('fa-eye-slash');
			}

			if (isFavorite) {
				$item.find('[aria-click="change-favorite-status"]').attr('title', _t.project.view.manager.unfavorite).removeClass('fa-heart').addClass('fa-heart-o');
			}
			else {
				$item.find('[aria-click="change-favorite-status"]').attr('title', _t.project.view.manager.favorite).removeClass('fa-heart-o').addClass('fa-heart');
			}

			_initStatusAnimation($item);

			/*
				/ Status
			*/
		}
	}

	/*
		/ Item
	*/

	/*
		Event button
	*/

	function initEventButton() {

		/*
			Change force hide status buttons
		*/

		$list.find('[aria-click="change-force-hide-status"]').on('click', function () {
			var $item = $(this).closest('.item');
			var status = $item.data('status');
			var isForceHide = listString.has('force_hide', status);

			toggleLoadStatus(true);
			$.ajax({
				url: '/projects/change_force_hide_status/' + $item.data('value'),
				method: 'POST',
				data: {
					is_force_hide: (isForceHide ? 0 : 1)
				}
				contentType: 'JSON'
			}).always(function () {
				toggleLoadStatus(false);
			}).done(function (data) {
				if (data.status == 0) {
					if (isForceHide) {
						$item.data('status', listString.remove('force_hide', status));
					}
					else {
						$item.data('status', listString.add('force_hide', status));
					}
					initItem($item);
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

		});

		/*
			/ Change force hide status buttons
		*/
		
		/*
			Change favorite status buttons
		*/

		$list.find('[aria-click="change-favorite-status"]').on('click', function () {
			var $item = $(this).closest('.item');
			var status = $item.data('status');
			var isFavorite = listString.has('favorite', status);

			toggleLoadStatus(true);
			$.ajax({
				url: '/projects/change_favorite_status/' + $item.data('value'),
				method: 'POST',
				data: {
					is_favorite: isFavorite ? 0 : 1
				}
				contentType: 'JSON'
			}).always(function () {
				toggleLoadStatus(false);
			}).done(function (data) {
				if (data.status == 0) {
					if (isFavorite) {
						$item.data('status', listString.remove('favorite', status));
					}
					else {
						$item.data('status', listString.add('favorite', status));
					}
					initItem($item);
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
		});

		/*
			/ Change favorite status buttons
		*/
	
		/*
			Delete buttons
		*/

		$list.find('[aria-click="delete"]').on('click', function () {
			var $item = $(this).closest('.item');

			popupPrompt({
				title: _t.form.confirm_title,
				content: _t.project.view.manager.delete_confirm,
				type: 'warning',
				primaryButton: true,
				buttons: [
					{
						text: _t.form.yes,
						type: 'warning',
						handle: function () {
							toggleLoadStatus(true);
							$.ajax({
								url: '/projects/delete/' + $item.data('value'),
								type: 'POST',
								dataType: 'JSON'
							}).always(function () {
								toggleLoadStatus(false);
							}).done(function (data) {
								if (data.status == 0) {
									$item.remove();
									find();
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

		/*
			/ Delete buttons
		*/

	}

	/*
		Event button
	*/

	/*
		Pagination
	*/

	function initPagination() {
		var order = { interact: 'desc' };

		find = _initPagination({
			url: '/projects/_manager_list',
			list: $list,
			pagination: $('#pagination'),
			data: function () {
				return order;
			},
			done: function (content) {
				$list.html(content);
				initItem();
				initEventButton();
			}
		});

		var $searchForm = $('#search_form');
		initForm($searchForm, {
			submit: function () {
				find({
					data: {
						keyword: $searchForm[0].elements['keyword'].value
					}
				});
			}
		});

		/*
			Order
		*/

		var $orderButtons = $searchForm.find('[aria-click="order"]');
		$orderButtons.on('click', function () {
			var $button = $(this);
			// If now
			if ($button.is('[data-now]')) {
				// Toggle
				if ($button.data('sort') == 'asc') {
					$button.data('sort', 'desc').find('[aria-name="sort"]').removeClass('fa-sort-asc').addClass('fa-sort-desc');
					order = {};
					order[$button.data('name')] = 'desc';
				}
				else {
					$button.data('sort', 'asc').find('[aria-name="sort"]').removeClass('fa-sort-desc').addClass('fa-sort-asc');
					order = {};
					order[$button.data('name')] = 'asc';
				}
			}
			// Not now
			else {
				$orderButtons.removeAttr('data-now').find('[aria-name="sort"]').removeClass('fa-sort-asc fa-sort-desc').addClass('fa-sort');
				$button.attr('data-now', '').data('sort', $button.data('sort')).find('[aria-name="sort"]').removeClass('fa-sort').addClass('fa-sort-' + $button.data('sort'));
				order = {};
				order[$button.data('name')] = $button.data('sort');
			}
			find();
		});

		/*
			/ Order
		*/
	}

	/*
		/ Pagination
	*/
});