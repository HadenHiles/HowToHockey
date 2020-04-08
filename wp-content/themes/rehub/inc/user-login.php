<?php


# 	
# 	USER REGISTRATION/LOGIN MODAL
# 	========================================================================================
#   Attach this function to the footer if the user isn't logged in
# 	========================================================================================
# 		
if( !function_exists('rehub_login_register_modal') ) {
function rehub_login_register_modal() {
	// only show the registration/login form to non-logged-in members
	if(!is_user_logged_in()){ 

		if(rehub_option('userlogin_captcha_enable') =='1' && rehub_option('userlogin_gapi_sitekey') !='' && rehub_option('userlogin_gapi_secretkey') !='') {
			$captcha_enabled = '1';
			//wp_enqueue_script( 're-recaptcha', 'https://www.google.com/recaptcha/api.js');
		}
		else {$captcha_enabled = '';}
		$show_terms_conditions = rehub_option('userlogin_terms_enable');
		?>
						
		<?php if(get_option('users_can_register')){ ?>
			<div id="rehub-login-popup-block">
				<!-- Register form -->
				<div id="rehub-register-popup">
				<div class="rehub-register-popup">	 
					<div class="re_title_inmodal"><?php _e('Register New Account', 'rehub_framework'); ?></div>
					<form id="rehub_registration_form_modal" action="<?php echo home_url( '/' ); ?>" method="POST">
						<?php do_action( 'wordpress_social_login' ); ?>
						<div class="re-form-group mb20">
							<label><?php _e('Username', 'rehub_framework'); ?></label>
							<input class="re-form-input required" name="rehub_user_login" type="text"/>
						</div>
						<div class="re-form-group mb20">
							<label for="rehub_user_email"><?php _e('Email', 'rehub_framework'); ?></label>
							<input class="re-form-input required" name="rehub_user_email" id="rehub_user_email" type="email"/>
						</div>
						<div class="re-form-group mb20">
							<label for="rehub_user_signonpassword"><?php _e('Password', 'rehub_framework'); ?><span class="alignright font90"><?php _e('Minimum 6 symbols', 'rehub_framework');  ?></span></label>
							<input class="re-form-input required" name="rehub_user_signonpassword" id="rehub_user_signonpassword" type="password"/>
						</div>
						<div class="re-form-group mb20">
							<label for="rehub_user_confirmpassword"><?php _e('Confirm password', 'rehub_framework'); ?></label>
							<input class="re-form-input required" name="rehub_user_confirmpassword" id="rehub_user_confirmpassword" type="password"/>
						</div>						
						<?php

						if($captcha_enabled =='1'){ ?>
							<div class="re-form-group mb20">
							    <script type="text/javascript">
							      var onloadCaptchamodail = function() {
							        grecaptcha.render('recaptchamodail', {
							          'sitekey' : '<?php echo rehub_option("userlogin_gapi_sitekey") ?>'
							        });
							      };
							    </script>
								<div class="recaptchamodail"></div>
							    <script src="https://www.google.com/recaptcha/api.js?onload=onloadCaptchamodail&render=explicit" async defer></script>
							</div><?php
						}

						if($show_terms_conditions){ ?>
							<div class="re-form-group mb20">
								<div class="checkbox">
									<label><input name="rehub_terms" type="checkbox"> <?php echo sprintf( __( 'I accept the <a target="_blank" href="%s">Terms & Conditions</a>', 'rehub_framework' ), esc_url(get_the_permalink(rehub_option('userlogin_term_page'))) ) ?></label>
								</div>
							</div><?php
						} ?>

						<div class="re-form-group mb20">
							<input type="hidden" name="action" value="rehub_register_member_popup_function"/>
							<button class="wpsm-button rehub_main_btn" type="submit"><?php _e('Sign up', 'rehub_framework'); ?></button>
						</div>
						<?php wp_nonce_field( 'ajax-login-nonce', 'register-security' ); ?>
					</form>
					<div class="rehub-errors"></div>
					<div class="rehub-login-popup-footer"><?php _e('Already have an account?', 'rehub_framework'); ?> <span class="act-rehub-login-popup color_link" data-type="login"><?php _e('Login', 'rehub_framework'); ?></span></div>
				</div>
				</div>

				<!-- Login form -->
				<div id="rehub-login-popup">
			 	<div class="rehub-login-popup">
					<div class="re_title_inmodal"><?php _e('Login', 'rehub_framework'); ?></div>
					<form id="rehub_login_form_modal" action="<?php echo home_url( '/' ); ?>" method="post">
						<?php do_action( 'wordpress_social_login' ); ?>
						<div class="re-form-group mb20">
							<label><?php _e('Username', 'rehub_framework') ?></label>
							<input class="re-form-input required" name="rehub_user_login" type="text"/>
						</div>
						<div class="re-form-group mb20">
							<label for="rehub_user_pass"><?php _e('Password', 'rehub_framework')?></label>
							<input class="re-form-input required" name="rehub_user_pass" id="rehub_user_pass" type="password"/>
							<?php if(function_exists('um_get_core_page')) :?>
								<a href="<?php echo um_get_core_page('password-reset'); ?>" class="alignright"><?php _e('Lost Password?', 'rehub_framework'); ?></a>
							<?php else: ?>
								<span class="act-rehub-login-popup color_link alignright" data-type="resetpass"><?php _e('Lost Password?', 'rehub_framework');  ?></span>
							<?php endif;?>							
						</div>
						<div class="re-form-group mb20">
							<input type="hidden" name="action" value="rehub_login_member_popup_function"/>
							<button class="wpsm-button rehub_main_btn" type="submit"><?php _e('Login', 'rehub_framework'); ?></button>
						</div>
						<?php wp_nonce_field( 'ajax-login-nonce', 'login-security' ); ?>
					</form>
					<div class="rehub-errors"></div>
					<div class="rehub-login-popup-footer"><?php _e('Don\'t have an account?', 'rehub_framework'); ?> <span class="act-rehub-login-popup color_link" data-type="register"><?php _e('Sign Up', 'rehub_framework'); ?></span></div>
				</div>
				</div>

				<!-- Lost Password form -->
				<div id="rehub-reset-popup">
			 	<div class="rehub-reset-popup">
					<div class="re_title_inmodal"><?php _e('Reset Password', 'rehub_framework'); ?></div>
					<form id="rehub_reset_password_form_modal" action="<?php echo home_url( '/' ); ?>" method="post">
						<div class="re-form-group mb20">
							<label for="rehub_user_or_email"><?php _e('Username or E-mail', 'rehub_framework') ?></label>
							<input class="re-form-input required" name="rehub_user_or_email" id="rehub_user_or_email" type="text"/>
						</div>
						<div class="re-form-group mb20">
							<input type="hidden" name="action" value="rehub_reset_password_popup_function"/>
							<button class="wpsm-button rehub_main_btn" type="submit"><?php _e('Get new password', 'rehub_framework'); ?></button>
						</div>
						<?php wp_nonce_field( 'ajax-login-nonce', 'password-security' ); ?>
					</form>
					<div class="rehub-errors"></div>
					<div class="rehub-login-popup-footer"><?php _e('Already have an account?', 'rehub_framework'); ?> <span class="act-rehub-login-popup color_link" data-type="login"><?php _e('Login', 'rehub_framework'); ?></span></div>
				</div>
				</div>
			</div>
			<?php

		}else{
			echo '<div id="rehub-restrict-login-popup"><div class="rehub-restrict-login-popup">'.__('Login/Register access is temporary disabled', 'rehub_framework').'</div></div>';
		} ?>

		<?php
	}
}
add_action('wp_footer', 'rehub_login_register_modal');
}

# 	
# 	AJAX FUNCTION (HANDLE DATA FROM POPUP)
# 	========================================================================================	

// LOGIN
if( !function_exists('rehub_login_member_popup_function') ) {
function rehub_login_member_popup_function(){

	// Get variables
	$user_login		= sanitize_user($_POST['rehub_user_login']);	
	$user_pass		= sanitize_text_field($_POST['rehub_user_pass']);

	// Check CSRF token
	if( !check_ajax_referer( 'ajax-login-nonce', 'login-security', false) ){
		echo json_encode(array('error' => true, 'message'=> '<div class="wpsm_box warning_type"><i></i>'.__('Session has expired, please reload the page and try again', 'rehub_framework').'</div>'));
	}
 	
 	// Check if input variables are empty
 	elseif(empty($user_login) or empty($user_pass)){
		echo json_encode(array('error' => true, 'message'=> '<div class="wpsm_box warning_type"><i></i>'.__('Please fill all form fields', 'rehub_framework').'</div>'));
 	}

 	else{
 		$user = wp_signon( array('user_login' => $user_login, 'user_password' => $user_pass), false );
	    if(is_wp_error($user)){
			echo json_encode(array('error' => true, 'message'=> '<div class="wpsm_box warning_type"><i></i>'.$user->get_error_message().'</div>'));
		}
	    else{
			echo json_encode(array('error' => false, 'message'=> '<div class="wpsm_box green_type">'.__('Login successful, reloading page...', 'rehub_framework').'</div>'));
		}
 	}
 	die();
}
add_action('wp_ajax_nopriv_rehub_login_member_popup_function', 'rehub_login_member_popup_function');
}

// REGISTER
if( !function_exists('rehub_register_member_popup_function') ) {
function rehub_register_member_popup_function(){

	// Get variables
	$user_login	= sanitize_user($_POST['rehub_user_login']);	
	$user_email	= sanitize_email($_POST['rehub_user_email']);
	$user_signonpassword = sanitize_text_field($_POST['rehub_user_signonpassword']);
	$user_confirmpassword	= sanitize_text_field($_POST['rehub_user_confirmpassword']);

	$show_terms_conditions = rehub_option('userlogin_terms_enable');

	if(rehub_option('userlogin_captcha_enable') =='1'){
		require_once get_template_directory().'/inc/vendor/recaptcha/src/ReCaptcha/ReCaptcha.php';
		require_once get_template_directory().'/inc/vendor/recaptcha/src/ReCaptcha/RequestMethod.php';
		require_once get_template_directory().'/inc/vendor/recaptcha/src/ReCaptcha/RequestParameters.php';
		require_once get_template_directory().'/inc/vendor/recaptcha/src/ReCaptcha/Response.php';
		require_once get_template_directory().'/inc/vendor/recaptcha/src/ReCaptcha/RequestMethod/Post.php';
		require_once get_template_directory().'/inc/vendor/recaptcha/src/ReCaptcha/RequestMethod/Socket.php';
		require_once get_template_directory().'/inc/vendor/recaptcha/src/ReCaptcha/RequestMethod/SocketPost.php';

		$secret = rehub_option('userlogin_gapi_secretkey');

		$recaptcha = new \ReCaptcha\ReCaptcha($secret);

		$resp = $recaptcha->verify( $_POST['g-recaptcha-response'], $_SERVER['REMOTE_ADDR'] );

		if(!$resp->isSuccess()){
		    // $errors = $resp->getErrorCodes();
			echo json_encode(array('error' => true, 'message'=> '<div class="wpsm_box warning_type">'.__('Wrong captcha response, please try again.', 'rehub_framework').'</div>'));
			die();
		}
	}
	
	// Check CSRF token
	if( !check_ajax_referer( 'ajax-login-nonce', 'register-security', false) ){
		echo json_encode(array('error' => true, 'message'=> '<div class="wpsm_box warning_type">'.__('Session has expired, please reload the page and try again', 'rehub_framework').'</div>'));
		die();
	}
 	
 	// Check if input variables are empty
 	elseif(empty($user_login) or empty($user_email) or empty($user_signonpassword) or empty($user_confirmpassword)){
		echo json_encode(array('error' => true, 'message'=> '<div class="wpsm_box warning_type">'.__('Please fill all form fields', 'rehub_framework').'</div>'));
		die();
 	}

 	elseif($show_terms_conditions and !isset($_POST['rehub_terms'])){
		echo json_encode(array('error' => true, 'message'=> '<div class="wpsm_box warning_type">'.__('Please accept the terms and conditions before registering', 'rehub_framework').'</div>'));
		die();
 	}

 	elseif($user_signonpassword != $user_confirmpassword){
		echo json_encode(array('error' => true, 'message'=> '<div class="wpsm_box warning_type">'.__('Your passwords do not match. Set the same password in both fields', 'rehub_framework').'</div>'));
		die();
 	} 

 	elseif(mb_strlen($user_signonpassword) < 6){
		echo json_encode(array('error' => true, 'message'=> '<div class="wpsm_box warning_type">'.__('Your passwords must have minimum 6 symbols.', 'rehub_framework').'</div>'));
		die();
 	}  		
	
	$errors = wp_create_user( $user_login, $user_signonpassword, $user_email );
	if(is_wp_error($errors)){
		$registration_error_messages = $errors->errors;
		$display_errors = '<div class="wpsm_box warning_type">';
			foreach($registration_error_messages as $error){
				$display_errors .= '<p>'.$error[0].'</p>';
			}
		$display_errors .= '</div>';
		echo json_encode(array('error' => true, 'message' => $display_errors));
	}else{
		update_user_meta($errors, '_um_cool_but_hard_to_guess_plain_pw', $user_signonpassword);
		wp_signon( array('user_login' => $user_login, 'user_password' => $user_signonpassword), false );
		echo json_encode(array('error' => false, 'message' => '<div class="wpsm_box green_type">'.__( 'Registration complete. Please check your e-mail. Reloading page...', 'rehub_framework').'</div>'));
	}
 	die();
}
add_action('wp_ajax_nopriv_rehub_register_member_popup_function', 'rehub_register_member_popup_function');
}


// RESET PASSWORD
if( !function_exists('rehub_reset_password_popup_function') ) {
function rehub_reset_password_popup_function(){
	// Get variables
	$username_or_email = $_POST['rehub_user_or_email'];

	// Check CSRF token
	if( !check_ajax_referer( 'ajax-login-nonce', 'password-security', false) ){
		echo json_encode(array('error' => true, 'message'=> '<div class="wpsm_box warning_type">'.__('Session has expired, please reload the page and try again', 'rehub_framework').'</div>'));
	}		

 	// Check if input variables are empty
 	elseif(empty($username_or_email)){
		echo json_encode(array('error' => true, 'message'=> '<div class="wpsm_box warning_type">'.__('Please fill all form fields', 'rehub_framework').'</div>'));
 	}

 	else{
		$username = is_email($username_or_email) ? sanitize_email($username_or_email) : sanitize_user($username_or_email);
		$user_forgotten = rehub_lostPassword_retrieve($username);	
		if(is_wp_error($user_forgotten)){	
			$lostpass_error_messages = $user_forgotten->errors;
			$display_errors = '<div class="wpsm_box warning_type">';
			foreach($lostpass_error_messages as $error){
				$display_errors .= '<p>'.$error[0].'</p>';
			}
			$display_errors .= '</div>';		
			echo json_encode(array('error' => true, 'message' => $display_errors));
		}else{
			echo json_encode(array('error' => false, 'message' => '<div class="wpsm_box green_type">'.__('Password was reset. Please check your email. Reloading page...', 'rehub_framework').'</div>'));
		}
 	}
 	die();
}	
add_action('wp_ajax_nopriv_rehub_reset_password_popup_function', 'rehub_reset_password_popup_function');
}

function rehub_lostPassword_retrieve( $user_data ) {
	
	global $wpdb, $current_site, $wp_hasher;
	$errors = new WP_Error();

	if(empty($user_data)){
		$errors->add( 'empty_username', __( 'Please enter a username or e-mail address.', 'rehub_framework' ) );
	}elseif(strpos($user_data, '@')){
		$user_data = get_user_by( 'email', trim( $user_data ) );
		if(empty($user_data)){
			$errors->add( 'invalid_email', __( 'There is no user registered with that email address.', 'rehub_framework'  ) );
		}
	}else{
		$login = trim( $user_data );
		$user_data = get_user_by('login', $login);
	}
	if($errors->get_error_code()){
		return $errors;
	}
	if(!$user_data){
		$errors->add('invalidcombo', __('Invalid username or e-mail.', 'rehub_framework'));
		return $errors;
	}
	$user_login = $user_data->user_login;
	$user_email = $user_data->user_email;
	do_action('retrieve_password', $user_login);
	$allow = apply_filters('allow_password_reset', true, $user_data->ID);
	if(!$allow){
		return new WP_Error( 'no_password_reset', __( 'Password reset is not allowed for this user', 'rehub_framework' ) );
	}
	elseif(is_wp_error($allow)){
		return $allow;
	}
	$key = wp_generate_password(20, false);
	do_action('retrieve_password_key', $user_login, $key);
	if(empty($wp_hasher)){
		require_once ABSPATH.'wp-includes/class-phpass.php';
		$wp_hasher = new PasswordHash(8, true);
	}
	$hashed = $wp_hasher->HashPassword($key);
	$wpdb->update($wpdb->users, array('user_activation_key' => $hashed), array('user_login' => $user_login));
	$message = __('Someone requested password reset for the following account:', 'rehub_framework' ) . "\r\n\r\n";
	$message .= network_home_url( '/' ) . "\r\n\r\n";
	$message .= sprintf( __( 'Username: %s', 'rehub_framework' ), $user_login ) . "\r\n\r\n";
	$message .= __('If this was a mistake, just ignore this email and nothing will happen.', 'rehub_framework' ) . "\r\n\r\n";
	$message .= __('To reset your password, visit the following address:', 'rehub_framework' ) . "\r\n\r\n";
	$message .= '<' . network_site_url( "wp-login.php?action=rp&key=$key&login=" . rawurlencode( $user_login ), 'login' ) . ">\r\n\r\n";
	
	if ( is_multisite() ) {
		$blogname = $GLOBALS['current_site']->site_name;
	} else {
		$blogname = wp_specialchars_decode( get_option( 'blogname' ), ENT_QUOTES );
	}
	$title   = sprintf( __( '[%s] Password Reset', 'rehub_framework' ), $blogname );
	$title   = apply_filters( 'retrieve_password_title', $title );
	$message = apply_filters( 'retrieve_password_message', $message, $key );
	if ( $message && ! wp_mail( $user_email, $title, $message ) ) {
		$errors->add( 'noemail', __( 'The e-mail could not be sent.<br />Possible reason: your host may have disabled the mail() function.', 'rehub_framework' ) );
		return $errors;
		wp_die();
	}
	return true;
}	