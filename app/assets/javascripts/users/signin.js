$(function () {
	var $form = $('#signin_form');

	initForm($form, {
		object: 'user',
		submit: function () {
			$form.find('.callout-danger').remove();

			toggleLoadStatus(true);
			$.ajax({
				url: '/signin',
				method: 'POST',
				data: $form.serialize(),
				dataType: 'JSON'
			}).always(function () {
				toggleLoadStatus(false);
			}).done(function (data) {
				if (data.status == 0) {
          window.location = '/';
				}
				else if (data.status == 5) {
					if (data.result.status == 3) {
						window.location = '/users/active_callout/' + data.result.result + '?status=unactive';
						return;
					}

          popupPrompt({
            title: _t.form.error_title,
            content: data.result.result,
            type: 'danger',
            onEscape: function () {
            	$form.find('#password').val('').focus();
		          if (data.result.status == 1) {
		        		// Account wrong
            		$form.find('#account').select();
		          }
            }
          });
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

	initFacebook();

	/*
		Facebook
	*/

	function initFacebook() {
		$('[aria-click="facebook-login"]').on('click', function () {
			FB.login(function () {
				FB.api('/me', function(response) {
			    console.log(JSON.stringify(response));
				});
			}, {
				scope: 'public_profile,email'
			});
		});
	}

	/*
		/ Facebook
	*/
});

window.fbAsyncInit = function() {
  FB.init({
    appId      : '1456463541347476',
    cookie     : true,
    xfbml      : true,
    version    : 'v2.4'
  });
};

(function(d, s, id){
   var js, fjs = d.getElementsByTagName(s)[0];
   if (d.getElementById(id)) {return;}
   js = d.createElement(s); js.id = id;
   js.src = "//connect.facebook.net/en_US/sdk.js";
   fjs.parentNode.insertBefore(js, fjs);
 }(document, 'script', 'facebook-jssdk'));


// /*
// 	Facebook
// */

// function statusChangeCallback(response) {
//   console.log('statusChangeCallback');
//   console.log(response);
//   // The response object is returned with a status field that lets the
//   // app know the current login status of the person.
//   // Full docs on the response object can be found in the documentation
//   // for FB.getLoginStatus().
//   if (response.status === 'connected') {
//     // Logged into your app and Facebook.
//     testAPI();
//   } else if (response.status === 'not_authorized') {
//     // The person is logged into Facebook, but not your app.
//     document.getElementById('status').innerHTML = 'Please log ' +
//       'into this app.';
//   } else {
//     // The person is not logged into Facebook, so we're not sure if
//     // they are logged into this app or not.
//     document.getElementById('status').innerHTML = 'Please log ' +
//       'into Facebook.';
//   }
// }

// // This function is called when someone finishes with the Login
// // Button.  See the onlogin handler attached to it in the sample
// // code below.
// function checkLoginState() {
//   FB.getLoginStatus(function(response) {
//     statusChangeCallback(response);
//   });
// }

// window.fbAsyncInit = function() {
// FB.init({
//   appId      : '1456463541347476',
//   cookie     : true,  // enable cookies to allow the server to access 
//                       // the session
//   xfbml      : true,  // parse social plugins on this page
//   version    : 'v2.2' // use version 2.2
// });

// // Now that we've initialized the JavaScript SDK, we call 
// // FB.getLoginStatus().  This function gets the state of the
// // person visiting this page and can return one of three states to
// // the callback you provide.  They can be:
// //
// // 1. Logged into your app ('connected')
// // 2. Logged into Facebook, but not your app ('not_authorized')
// // 3. Not logged into Facebook and can't tell if they are logged into
// //    your app or not.
// //
// // These three cases are handled in the callback function.

// FB.getLoginStatus(function(response) {
//   statusChangeCallback(response);
// });

// };

// // Load the SDK asynchronously
// (function(d, s, id) {
//   var js, fjs = d.getElementsByTagName(s)[0];
//   if (d.getElementById(id)) return;
//   js = d.createElement(s); js.id = id;
//   js.src = "//connect.facebook.net/en_US/sdk.js";
//   fjs.parentNode.insertBefore(js, fjs);
// }(document, 'script', 'facebook-jssdk'));

// // Here we run a very simple test of the Graph API after login is
// // successful.  See statusChangeCallback() for when this call is made.
// function testAPI() {
//   console.log('Welcome!  Fetching your information.... ');
//   FB.api('/me', function(response) {
//     console.log('Successful login for: ' + response.name);
//     document.getElementById('status').innerHTML =
//       'Thanks for logging in, ' + response.name + '!';
//   });
// }

// /*
// 	/ Facebook
// */