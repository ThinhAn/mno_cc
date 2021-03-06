$(function () {

	// Contact

		(function () {
			var $contactForm = $('#contact_form');

			initForm($contactForm, {
				submit: function () {
					$.ajax({
						url: 		'/mails/save',
						method: 	'POST',
						data: 		$contactForm.serialize()
					}).done(function (data) {
						if (data.status == 0) {
							popupPrompt({
								title: 'Đăng ký thành công',
								content: 'Bạn đã đăng ký thành công, chúng tôi sẽ liên hệ bạn trong thời gian sớm nhất'
							});
						}
						else {
							_errorPopup();
						}
					}).fail(function () {
						_errorPopup();
					});
				}
			});
		})();
	
	// / Contact

	// Search

		// Map
			
			(function () {
				var objects = {};

				$('.search-type.map-search').on('click', function () {
					var 
						$map = $('#search_map');

					if ($map.hasClass('hidden')) {
						$map.removeClass('hidden');
						var map = _initMap('search_map', {}, {
						    mapTypeControl: true,
						    mapTypeControlOptions: {
						        style: google.maps.MapTypeControlStyle.HORIZONTAL_BAR,
						        position: google.maps.ControlPosition.BOTTOM_CENTER
						    },
						});

						setTimeout(function() {
							var $input = $('#search_map_input').removeClass('hidden');
							map.controls[google.maps.ControlPosition.TOP_LEFT].push($input[0]);
							var autocomplete = new google.maps.places.Autocomplete($input[0]);
							autocomplete.bindTo('bounds', map);

							autocomplete.addListener('place_changed', function() {
								var place = autocomplete.getPlace();
								console.log(a = place);
								if (!place.geometry) {
									return;
								}

								// If the place has a geometry, then present it on a map.
								if (place.geometry.viewport) {
									map.fitBounds(place.geometry.viewport);
								} else {
									map.setCenter(place.geometry.location);
									map.setZoom(17);
								}

								var address = '';
								if (place.address_components) {
									address = [
										(place.address_components[0] && place.address_components[0].short_name || ''),
										(place.address_components[1] && place.address_components[1].short_name || ''),
										(place.address_components[2] && place.address_components[2].short_name || '')
									].join(' ');
								}
							});
						}, 1000);

						var to = null;
						map.addListener('bounds_changed', function() {
							clearTimeout(to);
							to = setTimeout(function () {
								var
									bs = map.getBounds(),
									bounds = {
										from: {
											lat: bs.H.H,
											lng: bs.j.H,
										},
										to: {
											lat: bs.H.j,
											lng: bs.j.j,
										}
									};

								$.ajax({
									url: '/home/search_by_bounds',
									data: {
										bounds: bounds
									},
									dataType: 'JSON'
								}).done(function (data) {
									if (data.status == 0) {
										var result = data.result;

										$.each(result, function (id, value) {
											if (!(id in objects)) {
												objects[id] = value;

												var marker = new google.maps.Marker({
														position: { lat: value.lat, lng: value.lng },
														map: map,
														title: value.title,
														animation: google.maps.Animation.DROP
													});
													marker.addListener('click', function () {
														window.location = value.url;
													});												
											}
										});
									}
								});
							}, 50);
						});
					}
					_scrollTo($map.offset().top);
					$map.click();
				});
			})();
		
		// / Map
		
	// / Search

	// Gallery
	
		// $('.gallery-ctn img').on({
		// 	'mouseenter click': function () {
		// 		var $img = $(this);

		// 		// Check status
		// 		if ($img.hasClass('active')) {
		// 			return;
		// 		}

		// 		$img.addClass('active').siblings('.active').removeClass('active');
		// 	}
		// });

	// / Gallery

	// Rating
	
		(function () {
			$('.rating-ctn .btn').on('click', function () {
				popupPrompt({
					title: 'Cám ơn bạn',
					content: 'Cám ơn bạn đã đánh giá',
					buttons: [
						{
							text: 'Xem bất động sản',
							type: 'green',
							handle: function () {
								window.location = '/bat-dong-san';
								return false;
							}
						},
						{
							text: 'Xem dự án',
							type: 'green',
							handle: function () {
								window.location = '/du-an';
								return false;
							}
						},
						{
							text: 'Đóng'
						}
					]
				});
			});
		})();
	
	// / Rating


});