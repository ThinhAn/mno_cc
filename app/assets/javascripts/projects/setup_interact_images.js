var project_id;

$(function () {

	var buildChecking = false;

	_initTabContainer($('.free-style-tab-container'));
	_initManualHorizontalList($('.manual-horizontal-list'));
	
	// View

		var 
			$doc = $('#setup_image_document'),
			$setupDoc = $('#design_document');
		_initFixedScroll(
			$doc,
			$('#view_container')
		);
		$doc.find('.close-button').on('click', function () {
			$doc.toggleClass('open');
		});
		$setupDoc.find('.close-button').on('click', function () {
			$setupDoc.toggleClass('open');
		});
	
		// Setup image
		
			$('[aria-click="setup_interact"]').on('click', function () {
				$button = $(this);
				$itemContainer = $button.closest('.items-list');

				startDesign($itemContainer.data('type'), $itemContainer.data('value'), {
					startId: $button.closest('.item').data('value')
				});
			});
		
		// / Setup image

		// Set finish
		
			$('.error-icon').hide();
			$('.error-text').hide().find('span').remove();
			$('[aria-click="setup_finish"]').on('click', function () {
				$.ajax({
					url: '/projects/setup_interact_images_finish/' + project_id,
					dataType: 'JSON'
				}).done(function (data) {
					if (data.status == 0) {
						window.location = '/du-an/cua-toi'
					}
					else if (data.status == 5 && data.result.length > 0) {
						buildChecking = true;
						$('.error-icon').hide();
						$('.error-text').hide().find('span').remove();
						$(data.result).each(function () {
							$('[aria-object="' + this.type + this.id + '-error-icon"]').show();
							$('[aria-object="' + this.type + this.id + '-error-text"]').show().append('<span>' + this.name + '</span>');

							if (this.type == 'surface') {
								$('[aria-object="block' + this.id + '-error-icon"]').show();
							}
						});
						$body.animate({
							scrollTop: $('.error-icon:eq(0)').offset().top - 20
						}, 100);
					}
					else {
						errorPopup();
					}
				}).fail(function () {
					errorPopup();
				});
			});

		// / Set finish

	// / View

	// Design

		var 
			$designPart = $('.setup-container'),
			$selectDescriptionPart = $designPart.find('.select-description-container');
			loadImage = new Image(),
			$selectedItem = null,
			$svg = $designPart.find('#svg'),
			$g = $svg.find('#g'),
			tranX = 0,
			tranY = 0,
			scale = 1,
			gOriginalSize = { w: 0, height: 0 },

			$currentToolButton = $designPart.find('.toolbox-container .active'),
			$drawPolylineButton = $designPart.find('[aria-click="polyline"]'),
			$cutButton = $designPart.find('[aria-click="cut"]'),

			isSelected = false, 
			isViewMoving = false,
			isMoveEditPoint = false,
			isUseCutTool = false,
			isCreateCutPoint = false;

		// Start

			// params: startId
			function startDesign(type, id, params) {
				if (typeof params == 'undefined') {
					params = {};
				}

				toggleLoadStatus(true);
				// Get images
				$.ajax({
					url: '/' + type + 's/get_image_for_interact_build/' + id,
					dataType: 'JSON'
				}).always(function () {
					toggleLoadStatus(false);
				}).done(function (data) {
					if (data.status == 0) {
						// Open
						$designPart.addClass('open').data({
							type: type,
							id: id
						});
						$body.addClass('no-scroll');
						$('.toolbox-container [aria-click="mouse"]').click();
						$g.html('');

						var $imageList = $designPart.find('.image-list');
						startItem = 0;

						// Create image list

							$imageList.html('');

							$(data.result).each(function () {
								var imageData = this;

								$item = $('<a class="item horizontal-item" data-id="' + imageData.id + '" data-url="' + imageData.url + '"></a>');
								$item.html('<img src="' + imageData.thumb_url + '" />');

								$item.data('descriptions', imageData.descriptions);

								$imageList.append($item);

								// If id is startId
								if (imageData.id == params['startId']) {
									startItem = $item.index();
								}
							});

						// / Create image list

						// Item click event

							if (type == 'blocks/floor') {
								$imageList.children().on('click', function () {
									$item = $(this);

									$('#group_description_list').find('[aria-name="real_estate"]');
									$('#real_estate_description_list [data-floor]').hide().attr('aria-status', 'hide');
									$('#real_estate_description_list [data-floor="' + $item.data('id') + '"]').show().attr('aria-status', 'show');
									$('#real_estate_description_list .tab-content').each(function () {
										$tabContent = $(this);
										if ($tabContent.children('[aria-status="show"]').length == 0) {
											$('#real_estate_description_list .tab-list [aria-name="' + $tabContent.attr('aria-name') + '"]').hide();
										}
										else {
											$('#real_estate_description_list .tab-list [aria-name="' + $tabContent.attr('aria-name') + '"]').show();
										}
									})
								});
							}

							$imageList.children().on('click', function () {
								$item = $(this);

								if ($item.is('.active')) {
									return;
								}

								if ($selectedItem != null) {
									$selectedItem.removeClass('active');
									saveItem();
								}

								$item.addClass('active');
								loadItem($item);

								$selectedItem = $item;
							});

						// / Item click event

						// Start item

							$imageList.children(':eq(' + startItem + ')').click();

						// / Start item

						initSelectDescription(type, id);
					}
					else {
						errorPopup();
					}
				}).fail(function () {
					errorPopup();
				});
			}

		// / Start

		// Save

			function saveItem() {
				descriptions = [];

				$g.find('[aria-object="object"]').each(function () {
					$object = $(this);

					description = { 
						id: $object.data('id'),
						tag_name: this.tagName,
						description: $object.data('description') || {}
					}

					switch(this.tagName) {
						case 'polyline':
							description.points = this.getAttribute('points');
							break;
					}

					descriptions.push(description);
				});

				$selectedItem.data('descriptions', descriptions);
			}

			function saveAll() {
				// Get all data
				data = []
				$designPart.find('.image-list > a').each(function () {
					data.push({
						id: $(this).data('id'),
						descriptions: $(this).data('descriptions') || []
					});
				});

				// Post
				toggleLoadStatus(true);
				$.ajax({
					url: '/' + $designPart.data('type') + 's/save_interact_images',
					method: 'POST',
					data: { data: JSON.stringify(data) },
					dataType: 'JSON'
				}).always(function () {
					toggleLoadStatus(false);
				}).done(function (data) {
					if (data.status == 0) {
						if (buildChecking) {
							$.ajax({
								url: '/projects/setup_interact_images_finish/' + project_id,
								data: {
									just_check: 't'
								},
								dataType: 'JSON'
							}).done(function (data) {
								if (data.status == 0) {
									$('.error-icon').hide();
									$('.error-text').hide().html('');
								}
								else if (data.status == 5) {
									$('.error-icon').hide();
									$('.error-text').hide().html('');

									if (data.result.length > 0) {
										$(data.result).each(function () {
											$('[aria-object="' + this.type + this.id + '-error-icon"]').show();
											$('[aria-object="' + this.type + this.id + '-error-text"]').show().append('<span>' + this.name + '</span>');

											if (this.type == 'surface') {
												$('[aria-object="block' + this.id + '-error-icon"]').show();
											}
										});
										$body.animate({
											scrollTop: $('.error-icon:eq(0)').offset().top - 20
										}, 100);
									}
								}
								else {
									errorPopup();
								}
							}).fail(function () {
								errorPopup();
							});
						}
					}
					else {
						errorPopup();
					}
				}).fail(function () {
					errorPopup();
				});
			}

			// Save & exit button

				$designPart.find('[aria-click="save"]').on('click', function () {
					if ($selectedItem) {
						saveItem();
					}
					
					$designPart.removeClass('open');
					$body.removeClass('no-scroll');

					saveAll();
				});

			// / Save & exit button

		// / Save

		// Exit

			// Close button

				$designPart.find('[aria-click="exit"]').on('click', function () {
					$designPart.removeClass('open');
					$body.removeClass('no-scroll');
				});

			// / Close button

		// / Exit

		// Load

			function loadItem($item) {
				$g.html('').hide();
				loadImage.src = $item.data('url');

				descriptions = $item.data('descriptions') || [];

				$(descriptions).each(function () {
					switch(this.tag_name) {
						case 'polyline':
							$object = addPolyline({
								points: this.points,
								description: this.description
							});
							break;
					}

					// Save id
					$object.data('id', this.id);
				});
			}

		// / Load

		// Add object

			// params: points(*), description
			function addPolyline(params) {
				var $polyline = $(document.createElementNS("http://www.w3.org/2000/svg", "polyline"));

				// Create polyline

					$g.append($polyline);

					$polyline.attr({
						'aria-object': 'object',
						points: params.points,
						tabindex: 0
					});

					$polyline.css({
						stroke: '#000',
						outline: 'none'
					});

					$polyline.data('description', params.description || {})
					
					if ($polyline.data('description').type) {
						$polyline.css('fill', 'rgba(0, 166, 91, .3)');
					}
					else {
						$polyline.css('fill', 'rgba(255, 255, 255, .3)');
					}

				// / Create polyline

				// Methods

					$polyline.data('remove_method', function () {
						removeEditPoints();
						$polyline.remove();
					});

					$polyline.data('start_edit_method', function () {
						if (isUseCutTool) {
							return;
						}

						isSelected = true;

						// Remove current edit points
						removeEditPoints();

						// Edit point
						var points = $polyline.attr('points').split(' ').map(function (value) {
							value = value.split(',');
							return { x: value[0], y: value[1] }
						});
						
						// Create edit point events
						$(points.slice(0, points.length - 1)).each(function (index) {
							// Add points
							var circle = document.createElementNS("http://www.w3.org/2000/svg", "circle");
							circle.setAttribute('cx', this.x);
							circle.setAttribute('cy', this.y);
							circle.setAttribute('r', 5 / scale);
							circle.setAttribute('aria-object', 'edit_point');
							circle.style.stroke = '#000';
							circle.style.fill = '#fff';
							circle.style.cursor = 'pointer';
							$(circle).data('index', index).on({
								mousedown: function (e) {
									if (isUseCutTool) {
										return;
									}
									isMoveEditPoint = true;

									init = { x: parseInt(circle.getAttribute('cx')), y: parseInt(circle.getAttribute('cy')) };
									start = getPosition(e);
									pointIndex = $(this).data('index');

									$svg.on({
										'mousemove.move_point': function (e) {
											if (isViewMoving) {
												return;
											}

											current = getPosition(e);

											points[pointIndex].x = init.x + current.x - start.x;
											points[pointIndex].y = init.y + current.y - start.y;

											if (pointIndex == 0) {
												points[points.length - 1] = points[pointIndex];
											}

											circle.setAttribute('cx', points[pointIndex].x);
											circle.setAttribute('cy', points[pointIndex].y);

											$polyline.attr('points', points.map(function (value) {
												return value.x + ',' + value.y;
											}).join(' '))
										},
										'mouseup.move_point': function (e) {
											isMoveEditPoint = false;
											$svg.off('.move_point');
										}
									})
								}
							});

							$g.append(circle);
						});
					})

				// Methods

				// Events

					$polyline.on({
						mousedown: function(e) {
							if (e.button != 0 || isUseCutTool) {
								return;
							}
							$body.css('cursor', '-webkit-grabbing');

							// Edit points
							first = true;
							moved = { x: 0, y: 0 };
							start = getPosition(e);

							$svg.on({

								// Move

									'mousemove.move_polyline': function (e) {
										if (isViewMoving) {
											return;
										}
										if (isSelected) {
											removeEditPoints();
											isSelected = false;
										}

										current = getPosition(e);
										$polyline.css('transform', 'translate(' + (moved.x = current.x - start.x) + 'px, ' + (moved.y = current.y - start.y) + 'px)');
									},
									'mouseup.move_polyline': function(e) {
										$body.css('cursor', 'default');
										// Change all points
										$polyline.attr('points', $polyline.attr('points').split(' ').map(function (value) {
											value = value.split(',');
											return (parseInt(value[0]) + moved.x) + ',' + (parseInt(value[1]) + moved.y);
										}).join(' '));

										$polyline.css('transform', 'translate(0px, 0px)');
										$svg.off('.move_polyline');
										if ($(e.target).is($polyline) || $(e.target).is('[aria-object="edit_point"]')) {
											isSelected = true;
											$polyline.data('start_edit_method')();
										}
									}

								// / Move

							}).off('mouseup.end_edit_polyline').on({

								// Edit

								'mouseup.end_edit_polyline': function (e) {
									// if click outside of this polyline and end point
									if (!($(e.target).is($polyline) || $(e.target).is('[aria-object="edit_point"]'))) {
										isSelected = false;
										removeEditPoints();
										$svg.off('mouseup.end_edit_polyline .move_polyline');
										$document.off('.key_polyline');
									}
								}
							});
						},
						keydown: function (e) {
							// Delete
							if (e.keyCode == 46) {
								$polyline.data('remove_method')();
							}
						},
						focus: function () {							
							$polyline.data('start_edit_method')();
						},
						focusout: function () {
							if (isMoveEditPoint || isCreateCutPoint) {
								return;
							}
							isSelected = false;
							removeEditPoints();
						}
					});

					setContextMenuObject($polyline);

				// Events

				return $polyline;
			}

		// / Add object

		// General methods

			function removeEditPoints() {
				$g.find('[aria-object="edit_point"]').remove();
			}

			function getPosition(e) {
				return {
					x: (e.clientX - tranX) / scale,
					y: (e.clientY - tranY) / scale
				}
			}

		// / General methods

		// Paint

			// View, tool

				// General

				// / General

				// Move, zoom

					// Mouse wheel always zoom
					$svg.on({
						mousewheel: function (e) {
							isUp = e.originalEvent.wheelDelta < 0;
							var oldScale = scale;

							if (isUp) {
								if (scale < 0.5) {
									return;
								}
								scale -= 0.1;
							}
							else {
								if (scale > 2) {
									return;
								}
								scale += 0.1;
							}

							pointX = e.clientX - $svg.offset().left;
							pointY = e.clientY - $svg.offset().top + _currentScrollTop();

							tranX -= (-tranX + pointX) / oldScale * (scale - oldScale);
							tranY -= (-tranY + pointY) / oldScale * (scale - oldScale);
							
							updateViewBox();
						},
						focus: function() {
							// Hold spacebar to move
							$document.on('keydown.move_view', function (e) {
								if (!isViewMoving && e.keyCode == 32) {
									isViewMoving = true;

									var
										start = null,
										moved = { x: 0, y: 0 };

									$svg.on({
										'mousemove.move_view': function (e) {
											if (start == null) {
												start = { 
													x: e.offsetX, 
													y: e.offsetY 
												};
											}

											moved.x = e.offsetX - start.x; 
											moved.y = e.offsetY - start.y;

											updateViewBoxWithValue(
												tranX + moved.x, 
												tranY + moved.y, 
												scale
											);
										}
									}).css('cursor', 'move');

									$document.on('keyup.move_view', function () {
										isViewMoving = false;

										tranX += moved.x;
										tranY += moved.y;

										updateViewBox();

										$svg.off('.move_view').css('cursor', 'default');
										$document.off('keyup.move_view');
									});
								}
							});
						},
						focusout: function () {
							$document.off('move_view');
						}
					}).attr('tabindex', '0').css('outline', '0');

					function updateViewBox() {
						$g.css('transform', 'translate(' + tranX + 'px,' + tranY + 'px) scale(' + scale +')');
						$g.find('[aria-object="edit_point"]').attr('r', 5 / scale); 
					}

					function updateViewBoxWithValue(tranX, tranY, scale) {
						$g.css('transform', 'translate(' + tranX + 'px,' + tranY + 'px) scale(' + scale +')');
					}

				// / Move, zoom

				// Tools

					$('.toolbox-container').find('[aria-type="tool"]').on('click', function () {
						if ($(this).hasClass('active')) {
							return;
						}
						if ($currentToolButton) {
							$currentToolButton.removeClass('active').trigger('endTool');
						}
						$currentToolButton = $(this);
						$currentToolButton.addClass('active').trigger('startTool');
					});

					$(document).on('keydown', function (e) {
						if (e.keyCode == 27) {
							$currentToolButton.trigger('clearTool');
						}
					});

					// Polyline

						{
							var 
								polyline,
								points,
								endCircle,
								mouseCircle;

							$drawPolylineButton.on({
								startTool: function () {
									$g.on({
										'click.draw_polyline': function (e) {
											// If select object
											if (isSelected) {
												return;
											}
											var isEnterEndPoint = false;

											// Get click position
											pos = getPosition(e);

											// If start polyline => create new polyline
											if (polyline == null) {
												// Start point
												points = pos.x + ',' + pos.y;

												// Create polyline with start point
												polyline = document.createElementNS("http://www.w3.org/2000/svg", "polyline");
												polyline.setAttribute('points', points);
												polyline.style.stroke = '#000';
												polyline.style.fill = 'rgba(255, 255, 255, .5)';
												$g.append(polyline);

												// Create mouse circle
												mouseCircle = document.createElementNS("http://www.w3.org/2000/svg", "circle");
												mouseCircle.setAttribute('cx', pos.x);
												mouseCircle.setAttribute('cy', pos.y);
												mouseCircle.setAttribute('r', 5);
												mouseCircle.style.stroke = '#000';
												mouseCircle.style.fill = '#fff';
												mouseCircle.style['pointer-events'] = 'none';
												$g.append(mouseCircle);

												// Create start point for end
												endCircle = document.createElementNS("http://www.w3.org/2000/svg", "circle");
												endCircle.setAttribute('cx', pos.x);
												endCircle.setAttribute('cy', pos.y);
												endCircle.setAttribute('r', 10 / scale);
												endCircle.style.stroke = '#000';
												endCircle.style.fill = '#fff';
												endCircle.style.cursor = 'pointer';
												$g.append(endCircle);

												// Display line on move
												$g.on('mousemove.drawing_polyline', function (e) {
													if (isViewMoving || isEnterEndPoint) {
														return;
													}

													pos = getPosition(e);
													// Set line & circle to mouse
													polyline.setAttribute("points", points + ' ' + pos.x + ',' + pos.y);
													mouseCircle.setAttribute('cx', pos.x);
													mouseCircle.setAttribute('cy', pos.y);
												});

												// Click to end point => finish
												$(endCircle).on({
													click: function (e) {
														// For stop create next point
														e.stopPropagation();

														// Stop envent
														$g.off('mousemove.drawing_polyline');

														// Create end point
														points += ' ' + endCircle.getAttribute('cx') + ',' + endCircle.getAttribute('cy');
														polyline.setAttribute('points', points);

														if (points.split(' ').length > 3) {
															addPolyline({
																points: points
															});	
														}

														$drawPolylineButton.trigger('clearTool');
													},
													mouseenter: function () {
														mouseCircle.style.visibility = 'hidden';
														isEnterEndPoint = true;

														// Set line & circle to end point
														pos = { x: endCircle.getAttribute('cx'), y: endCircle.getAttribute('cy') }
														polyline.setAttribute("points", points + ' ' + pos.x + ',' + pos.y);
														mouseCircle.setAttribute('cx', pos.x);
														mouseCircle.setAttribute('cy', pos.y);
													},
													mouseleave: function () {
														mouseCircle.style.visibility = 'visible';
														isEnterEndPoint = false;
													}
												});
											}
											// Else => create new point
											else {
												// New point
												points += ' ' + pos.x + ',' + pos.y;
												polyline.setAttribute("points", points);
											}
										}
									});
								},
								endTool: function () {
									$(this).trigger('clearTool');

									$g.off('.draw_polyline');
								},
								clearTool: function () {
									if (polyline) {
										polyline.remove();
										polyline = null;
									}
									if (endCircle) {
										endCircle.remove();
										endCircle = null;
									}
									if (mouseCircle) {
										mouseCircle.remove();
										mouseCircle = null;	
									}

									$g.off('.drawing_polyline');
								}
							});
						}

					// / Polyline

					// Cut

						{
							var
								cutPolyline,
								circle,
								cutPolylinePoints,
								$currentPolyline,
								isCutting,
								startPointIndex,
								circleMouse;

							function getLinearEquation(pointA, pointB) {
								// Tính vector pháp tuyến (đảo 2 tọa độ + đổi dấu 1 tọa độ của vector chỉ phương)
								vector = { 
									x: pointB.y - pointA.y, 
									y: pointA.x - pointB.x 
								}

								// Phương trình đường thẳng (a(x-x0)+b(y-y0)) => ax + by - ax0 - by0
								equation = {
									a: vector.x,
									b: vector.y,
									c: -vector.x * pointA.x - vector.y * pointA.y
								}

								return equation;
							}

							function getNearestPoint(pos, equation) {
								// Lấy phương trình đường thẳng theo vector chỉ phương (vuông góc với đường thẳng hiện tại)
								vector2 = { 
									x: equation.b,
									y: -equation.a
								}
								equation2 = {
									a: vector2.x,
									b: vector2.y,
									c: -vector2.x * pos.x - vector2.y * pos.y
								}

								// Lấy giao điểm 2 đường thẳng
								intersectionPoint = {};
								intersectionPoint.x = (equation.b * equation2.c / equation2.b - equation.c) / (equation.a - equation.b * equation2.a / equation2.b);
								intersectionPoint.y = -equation2.a * intersectionPoint.x / equation2.b - equation2.c / equation2.b;

								return intersectionPoint;
							}

							$cutButton.on({
								startTool: function () {
									isUseCutTool = true;

									function setEvent($polylines) {
										($polylines || $g.find('polyline')).on({
											'focus.cut': function () {
												// Prevent refocus if is cutting
												if (isCutting) {
													return;
												}
												isCutting = true;

												// Save current poyline
												$currentPolyline = $(this);

												// Get all points of polyline
												var 
													$points = $($currentPolyline.attr('points').split(' ').map(function (value) {
														value = value.split(',');
														return { x: parseInt(value[0]), y: parseInt(value[1]) };
													}));

												// Get linear equation of all line
												length = $points.length - 1;
												for (var i = 0; i < length; i++) {
													equation = getLinearEquation($points[i], $points[i + 1]);
													$points[i].equation_with_next = equation;
													$points[i].denominator = Math.sqrt(equation.a * equation.a + equation.b * equation.b);
												}

												// Remove last point
												$points = $points.slice(0, -1);

												// Set visible status
												$currentPolyline.css({
													'stroke-width': '2px'
												});

												// Create circle mouse
												cutPolyline = null, circleMouse = document.createElementNS("http://www.w3.org/2000/svg", "circle");
												circleMouse.setAttribute('r', 5);
												circleMouse.style.stroke = '#000';
												circleMouse.style.fill = '#fff';
												$g.append(circleMouse);

												// Mouse on poline
												$currentPolyline.add(circleMouse).on({
													'mousemove.cutting': function (e) {
														// Mouse position
														pos = getPosition(e);

														// Find nearest line with maximum is 15
														nearest = { distance: 15, pointIndex: -1 };
														$points.each(function (index) {
															distance = Math.abs(this.equation_with_next.a * pos.x + this.equation_with_next.b * pos.y + this.equation_with_next.c) / this.denominator;
															if (distance < nearest.distance) {
																nearest.distance = distance;
																nearest.pointIndex = index;
															}
														});

														// If has nearest line => get intersection point
														if (nearest.pointIndex != -1) {
															startPoint = $points[nearest.pointIndex];
															endPoint = $points[nearest.pointIndex == $points.length - 1 ? 0 : nearest.pointIndex + 1];

															pos = getNearestPoint(pos, startPoint.equation_with_next);

															if (startPoint.x < endPoint.x) {
																minX = startPoint.x;
																maxX = endPoint.x
															}
															else {
																minX = endPoint.x;
																maxX = startPoint.x
															}
															if (startPoint.y < endPoint.y) {
																minY = startPoint.y;
																maxY = endPoint.y
															}
															else {
																minY = endPoint.y;
																maxY = startPoint.y
															}

															if (pos.x < minX) {
																pos.x = minX;
															}
															else if (pos.x > maxX) {
																pos.x = maxX;
															}
															if (pos.y < minY) {
																pos.y = minY;
															}
															else if (pos.y > maxY) {
																pos.y = maxY;
															}

															circleMouse.setAttribute('data-lying_border', nearest.pointIndex);
														}
														else {
															circleMouse.setAttribute('data-lying_border', '');
														}
														circleMouse.setAttribute('cx', pos.x);
														circleMouse.setAttribute('cy', pos.y);
													}
												});

												$currentPolyline.on('focusout.cutting', function () {
													// For click to create point
													if (isCreateCutPoint) {
														return;
													}
													$cutButton.trigger('clearTool');
												});

												$g.on({
													'mousedown.cutting': function () {
														isCreateCutPoint = true;

														// If begin
														if (!cutPolyline) {
															// Must click to border
															if (!circleMouse.getAttribute('data-lying_border')) {
																return;
															}

															// Set start point index
															startPointIndex = circleMouse.getAttribute('data-lying_border');

															// Create cut polyline
															cutPolylinePoints = circleMouse.getAttribute('cx') + ',' + circleMouse.getAttribute('cy');
															cutPolyline = document.createElementNS("http://www.w3.org/2000/svg", "polyline");
															cutPolyline.style.stroke = '#000';
															cutPolyline.style.fill = 'none';
															cutPolyline.getAttribute('points', cutPolylinePoints);

															$g.append(cutPolyline);
															$g.append(circleMouse); // Bring up

															$g.on('mousemove.cutting', function () {
																if (isViewMoving) {
																	return;
																}
																// Create start point
																pos = { x: circleMouse.getAttribute('cx'), y: circleMouse.getAttribute('cy') };
																cutPolyline.setAttribute("points", cutPolylinePoints + ' ' + pos.x + ',' + pos.y);
															});
														}
														// Next point
														else {
															cutPolylinePoints += ' ' + pos.x + ',' + pos.y;
															cutPolyline.getAttribute('points', cutPolylinePoints);

															// If click to border again => end
															if (circleMouse.getAttribute('data-lying_border')) {
																// Get end point index
																endPointIndex = circleMouse.getAttribute('data-lying_border');

																// Get current polygon points
																points = $currentPolyline.attr('points').split(' ').slice(0, -1);

																// If start > end => reserve
																if (startPointIndex > endPointIndex) {
																	// Exchange index
																	t = startPointIndex;
																	startPointIndex = endPointIndex;
																	endPointIndex = t;

																	// Reverse cut polyline points
																	cutPolylinePoints = cutPolylinePoints.split(' ').reverse().join(' ');
																}

																// Create first
																pointsA = '';
																for (i = 0; i <= startPointIndex; i++) {
																	pointsA += ' ' + points[i];
																}
																pointsA += ' ' + cutPolylinePoints;
																for (i = parseInt(endPointIndex) + 1; i < points.length; i++) {
																	pointsA += ' ' + points[i];
																}
																pointsA = pointsA.substr(1);
																// Add last points
																pointsA += ' ' + pointsA.split(' ')[0];
																setEvent(addPolyline({
																	points: pointsA
																}));

																// Create second
																pointsB = cutPolylinePoints;
																for (i = endPointIndex; i > startPointIndex; i--) {
																	pointsB += ' ' + points[i];
																}
																// Add last points
																pointsB += ' ' + pointsB.split(' ')[0];
																setEvent(addPolyline({
																	points: pointsB
																}));																

																$currentPolyline.remove();

																$cutButton.trigger('clearTool');
															}
														}
													},
													'mouseup.cutting': function () {
														isCreateCutPoint = false;
													}
												});
											}
										});
									}

									setEvent();
								},
								endTool: function () {
									isUseCutTool = false;
									$g.find('polyline').off('.cut');
									$cutButton.trigger('clearTool');
								},
								clearTool: function () {
									isCutting = false;
									if (cutPolyline) {
										cutPolyline.remove();
										cutPolyline = null;
									}
									if (circle) {
										circle.remove();
										circle = null;
									}
									if (circleMouse) {
										circleMouse.remove();
										circleMouse = null;
									}
									if ($currentPolyline) {
										$currentPolyline.css({
											'stroke-width': '1px'
										});
									}
									$g.off('.cutting');
									$g.find('polyline').off('.cutting');
								}
							});
						}

					// / Cut

				// / Tools

				loadImage.onload = function() {
					image = document.createElementNS("http://www.w3.org/2000/svg", "image");
					image.setAttribute('width', this.width);
					image.setAttribute('height', this.height);
					gOriginalSize = { w: this.width, h: this.height };
					image.setAttributeNS('http://www.w3.org/1999/xlink','href', this.src);
					$g.prepend(image);
					tranX = $svg.width() / 2 - this.width / 2;
					tranY = $svg.height() / 2 - this.height / 2;
					scale = 1;
					updateViewBox();
					$g.show();
				}

			// / View, tool

			// Item

				$('.items-container .item-container').each(function () {
					var 
						$itemListPanel = $(this),
						$itemList = $itemListPanel.children();

					$itemListPanel.on({
						mouseenter: function () {
							$(this).addClass('show').siblings('.show').removeClass('show').scrollLeft(0);
						},
						mouseover: function (e) {
							var 
								scrollableWidth = $itemList[0].getBoundingClientRect().width - $itemListPanel[0].getBoundingClientRect().width,
								offsetLeft = $itemListPanel.offset().left
								panelWidth = $itemListPanel.width() - 100;

							if (scrollableWidth > 0) {
								$itemListPanel.on({
									mousemove: function (e) {
										var position = e.clientX - offsetLeft - 50;
										$itemListPanel.scrollLeft(scrollableWidth * (position / panelWidth));
									}
								})
							}
						},
						mouseout: function () {
							$itemListPanel.off('mousemove');
						}
					});
				});

			// / Item

		// / Paint

		// Description

			$selectDescriptionPart.find('.close-popup').on('click', function () {
				closeSelectDescription();
			});

			_initTabContainer($selectDescriptionPart.find('.free-style-tab-container'));

			function initSelectDescription(type, id) {

				// Get description objects

					// Blocks
					if (type == 'project' || type == 'block') {
						$.ajax({
							url: '/blocks/_description_item_list/' + project_id,
							dataType: 'JSON'
						}).done(function (data) {
							if (data.status == 0) {
								var $list = $selectDescriptionPart.find('#block_description_list');
								$list.html(data.result).find('.item').on('click', function () {
									$item = $(this);

									$list.find('.active').removeClass('active');
									$item.addClass('active');
								});
								$('#group_description_list').find('[aria-name="block"]').show();
							}
						}).fail(function () {
							errorPopup();
						});
					}
					else {
						$('#group_description_list').find('[aria-name="block"]').hide();
					}

					// Block floor
					if (type == 'block') {
						$.ajax({
							url: '/blocks/floors/_description_item_list/' + id,
							dataType: 'JSON'
						}).done(function (data) {
							if (data.status == 0) {
								var $list = $selectDescriptionPart.find('#block_floor_description_list');
								$list.html(data.result).find('.item').on('click', function () {
									$item = $(this);

									$list.find('.active').removeClass('active');
									$item.addClass('active');
								});
								$('#group_description_list').find('[aria-name="block_floor"]').show();
							}
						}).fail(function () {
							errorPopup();
						});
					}
					else {
						$('#group_description_list').find('[aria-name="block_floor"]').hide();
					}

					// Real-estates
					if (type == 'block' || type == "blocks/floor") {
						$.ajax({
							url: '/real_estates/_block_description_item_list/' + id,
							dataType: 'JSON'
						}).done(function (data) {
							if (data.status == 0) {
								var $list = $selectDescriptionPart.find('#real_estate_description_list');
								$list.html(data.result).find('.item').on('click', function () {
									$item = $(this);

									$list.find('.tab-content .active').removeClass('active');
									$item.addClass('active').closest('.tab-content').addClass('active');
								});
								_initTabContainer($list.find('.free-style-tab-container'));

								$('#group_description_list').find('[aria-name="real_estate"]').show();

								// For hide/show by floor
								if (type == 'blocks/floor') {
									$designPart.find('.image-list > .active').click();
								}
							}
						}).fail(function () {
							errorPopup();
						});
					}
					else {
						$('#group_description_list').find('[aria-name="real_estate"]').hide();
					}

				// / Get description objects

				// Events

					$selectDescriptionPart.find('[aria-click="close"]').on('click', function () {
						closeSelectDescription();
					});

				// / Events

			}

			function openSelectDescription(params) {
				$selectDescriptionPart.addClass('open');

				// Close event

					$document.on('keydown.close_select_description', function (e) {
						if (e.keyCode == 27) {
							e.preventDefault();
							closeSelectDescription();
						}
					})

				// / Close event

				// Save

					$selectDescriptionPart.find('[aria-click="save"]').off('click').on('click', function () {
						// Get description
						description = {};
						switch ($('#group_description_list [aria-name].active').attr('aria-name')) {
							case 'block':
								$selected = $('#block_description_list').find('.item.active');
								if ($selected.length != 0) {
									description.type = 'block';
									description.id = $selected.data('value');
									returnResult();
								}
								else {
									popupPrompt({
										title: 'Xác nhận',
										content: 'Chưa có block được chọn. Sẽ không có đối tượng được mô tả. Bạn vẫn muốn tiếp tục?',
										type: 'warning',
										buttons: [
											{
												text: 'Tiếp tục',
												type: 'primary',
												primaryButton: true,
												handle: function () {
													returnResult();
												}
											},
											{
												text: 'Quay lại'
											}
										]
									})
								}
								break;
							case 'block_floor':
								$selected = $('#block_floor_description_list').find('.item.active');
								if ($selected.length != 0) {
									description.type = 'block_floor';
									description.id = $selected.data('value');
									returnResult();
								}
								else {
									popupPrompt({
										title: 'Xác nhận',
										content: 'Chưa có mặt cắt được chọn. Sẽ không có đối tượng được mô tả. Bạn vẫn muốn tiếp tục?',
										type: 'warning',
										buttons: [
											{
												text: 'Tiếp tục',
												type: 'primary',
												primaryButton: true,
												handle: function () {
													returnResult();
												}
											},
											{
												text: 'Quay lại'
											}
										]
									})
								}
								break;
							case 'real_estate':
								$selected = $('#real_estate_description_list').find('.item.active:visible');
								if ($selected.length != 0) {
									description.type = 'real_estate';
									description.id = $selected.data('value');
									returnResult();
								}
								else {
									popupPrompt({
										title: 'Xác nhận',
										content: 'Chưa có bất động sản được chọn. Sẽ không có đối tượng được mô tả. Bạn vẫn muốn tiếp tục?',
										type: 'warning',
										buttons: [
											{
												text: 'Tiếp tục',
												type: 'primary',
												primaryButton: true,
												handle: function () {
													returnResult();
												}
											},
											{
												text: 'Quay lại'
											}
										]
									})
								}
								break;
							case 'text_image':
								var $form = $('#text_image_description_form');
								description.type = 'text_image';
								description.data = $form.serialize();
								description.preview_list = $form.find('.preview-list');
								description.description = $form.find('[name="description"]').val();
								returnResult();
								break;
							default:
								returnResult();
								break;
						}

						function returnResult() {
							if (typeof params['save'] == 'function') {
								params['save'](description);
							}
							closeSelectDescription();
						}
					});

				// / Save

				// Set value

					$form = $('<form class="form" id="text_image_description_form">' +
						'<article class="form-group">' +
							'<label class="control-label">' +
								'Mô tả' +
							'</label>' +
							'<textarea class="form-control" name="description"></textarea>' +
						'</article>' +
						'<article class="form-group">' +
							'<label class="control-label">' +
								'Hình ảnh' +
							'</label>' +
							'<input class="file-upload" type="file" multiple name="images[]" data-amount="5" data-has_description data-has_avatar data-has_order />' +
						'</article>' +
					'</form>')
					$('#text_image_description_form_container').html($form);	
					initForm($form);

					description = params['description'] || {};
					$selectDescriptionPart.data('description', description).find('.item.active').removeClass('active');

					switch (description['type']) {
						case 'block':
							$('#group_description_list').find('[aria-name="block"] [aria-click="change_tab"]').click();
							$('#block_description_list').find('[data-value="' + description['id'] + '"]').addClass('active').closest('.box').addClass('active');
							break;
						case 'block_floor':
							$('#group_description_list').find('[aria-name="block_floor"] [aria-click="change_tab"]').click();
							$('#block_floor_description_list').find('[data-value="' + description['id'] + '"]').addClass('active').closest('.box').addClass('active');
							break;
						case 'real_estate':
							$('#group_description_list').find('[aria-name="real_estate"] [aria-click="change_tab"]').click();
							tabContentName = $('#real_estate_description_list').find('[data-value="' + description['id'] + '"]').addClass('active').closest('.tab-content').attr('aria-name');
							$('#real_estate_description_list').find('.tab-list [aria-name="' + tabContentName + '"] [aria-click="change_tab"]').click();
							break;
						case 'text_image':
							if (typeof description['formpreview_list'] == 'undefined') {
								$form.find('.file-upload').attr('data-init-value', description['data']['images']).trigger('initValue');
								$form.find('[name="description"]').val(description['data']['description']);
							}
							else {
								$form.find('.preview-list').html(description['preview_list'].html());
								$form.find('.file-upload').trigger('initItem');
								$form.find('[name="description"]').val(description['description']);
							}
							$('#group_description_list').find('[aria-name="text_image"] [aria-click="change_tab"]').click();
							break;
						default:
							$('#group_description_list').find('[aria-name="text_image"] [aria-click="change_tab"]').click();
							break;
					}

				// / Set value

			}

			function closeSelectDescription() {
				$selectDescriptionPart.removeClass('open');
			}

		// / Description

		// Context menu

			function setContextMenuObject($object) {
				$object.on('contextmenu', function (e) {
					e.preventDefault();

					_contextMenu({
						position: {
							x: e.pageX,
							y: e.pageY
						},
						items: [
							{
								text: 'Mô tả',
								handle: function () {
									openSelectDescription({
										save: function (data) {
											$object.data('description', data);
											if ($.isEmptyObject(data)) {
												$object.css('fill', 'rgba(255, 255, 255, .3)');
											}
											else {
												$object.css('fill', 'rgba(0, 166, 91, .3)');
											}
										},
										description: $object.data('description')
									});
								}
							},
							{
								text: 'Xóa',
								handle: function () {
									$object.data('remove_method')();
								}
							}
						]
					})
				})
			}

		// / Context menu 

	// / Design

})