<?php
$rehub_theme = wp_get_theme();
if($rehub_theme->parent_theme) {
	$template_dir =  basename(get_template_directory());
	$rehub_theme = wp_get_theme($template_dir);
}
$rehub_version = $rehub_theme->get( 'Version' );
$plugins = TGM_Plugin_Activation::$instance->plugins;
$installed_plugins = get_plugins();
$rehub_options = get_option( 'Rehub_Key' );
$registration_complete = false;
$tf_username = isset( $rehub_options[ 'tf_username' ] ) ? $rehub_options[ 'tf_username' ] : '';
$tf_support_date = isset( $rehub_options[ 'tf_support_date' ] ) ? $rehub_options[ 'tf_support_date' ] : '';
$tf_purchase_code = isset( $rehub_options[ 'tf_purchase_code' ] ) ? $rehub_options[ 'tf_purchase_code' ] : '';
if( $tf_username !== "" && $tf_purchase_code !== "" ) {
    $registration_complete = true;
}
$theme_url = 'https://wpsoul.com/';
?>
<div class="wrap about-wrap rehub-wrap">
	<h1><?php echo __( "Welcome to ReHub Theme!", "rehub_framework" ); ?></h1>
    <?php if( $registration_complete ) :?>
    <div class="about-text">
        <?php echo __( "Theme is registered on your site! ", "rehub_framework" ); ?>
        <?php echo __( "You have support until: ", "rehub_framework" ); ?><?php $date = date_create($tf_support_date); echo date_format($date, 'Y-m-d');?>
        <a href="http://themeforest.net/item/rehub-directory-shop-coupon-affiliate-theme/7646339" target="_blank"><?php echo __( "(extend support)", "rehub_framework" ); ?></a><br />
        <?php if ( ! function_exists( 'envato_market' ) ) :?>
            <?php echo __( "If you need automatic theme updates, install Envato Market plugin from ", "rehub_framework" ); ?>
            <a href="<?php echo admin_url( 'admin.php?page=rehub-plugins' );?>"><?php echo __( "Plugins Tab", "rehub_framework" ); ?></a>
        <?php endif;?>  
    </div>
    <?php else :?>
    <div class="about-text"><?php echo __( "ReHub Theme is now installed and ready to use! Please register your purchase to get support, automatic theme updates, demo stacks, bonuses.", "rehub_framework" ); ?></div> 
    <?php endif;?>
	<div class="rehub-logo"><span class="rehub-version"><?php echo __( "Version", "rehub_framework"); ?> <?php echo $rehub_version; ?></span></div>
	<h2 class="nav-tab-wrapper">
		<?php
		printf( '<a href="%s" class="nav-tab">%s</a>', admin_url( 'admin.php?page=rehub' ), __( "Registration", "rehub_framework" ) );
		printf( '<a href="%s" class="nav-tab">%s</a>', admin_url( 'admin.php?page=rehub-support' ), __( "Support and tips", "rehub_framework" ) );
		printf( '<a href="#" class="nav-tab nav-tab-active">%s</a>', __( "Plugins", "rehub_framework" ) );
		printf( '<a href="%s" class="nav-tab">%s</a>', admin_url( 'admin.php?page=rehub-demos' ), __( "Demo stacks", "rehub_framework" ) );
		?>
	</h2>
	 <div class="rehub-important-notice">
		<p class="about-description"><?php echo __( "Rehub Theme has some bundled paid plugins which you can install from this page.");?>
		<br> 
		<a href='http://rehub.wpsoul.com/documentation/docs.html#bundled_plugins' target='_blank'><?php echo __( "Check how to update them.", "rehub_framework");?></a></p>
		<p class="about-description cegg-discount"><?php echo __( "Use coupon <strong>REHUB25</strong> to get 25% discount for our best All in One moneymaking plugin");?> 
		<a href='https://wpsoul.com/content-egg-deal/' target='_blank'><?php echo __( "Content Egg", "rehub_framework");?></a>	</p>
	</div>
	
	<div class="rehub-demo-themes rehub-install-plugins">
		<div class="feature-section theme-browser rendered">
			<?php
			foreach( $plugins as $plugin ):
				$class = '';
				$plugin_status = '';
				$file_path = $plugin['file_path'];
				$plugin_action = $this->plugin_link( $plugin );

				if( is_plugin_active( $file_path ) ) {
					$plugin_status = 'active';
					$class = 'active';
				}
			?>
			<div class="theme <?php echo $class; ?>">
				<div class="theme-screenshot">
					<img src="<?php echo $plugin['image_url']; ?>" alt="" />
					<div class="plugin-info">
					<?php echo $plugin['description']; ?><br />
					<?php if( isset( $installed_plugins[$plugin['file_path']] ) ): ?>
						<?php echo sprintf('%s %s | <a href="%s" target="_blank">%s</a>', __( 'Version:', 'rehub_framework' ), $installed_plugins[$plugin['file_path']]['Version'], $installed_plugins[$plugin['file_path']]['AuthorURI'], $installed_plugins[$plugin['file_path']]['Author'] ); ?>
					<?php elseif ( $plugin['source_type'] == 'bundled' ) : ?>
						<?php echo sprintf('%s %s', __( 'Available Version:', 'rehub_framework' ), $plugin['version'] ); ?>					
					<?php endif; ?>
					</div>
				</div>
				<h3 class="theme-name">
					<?php
					if( $plugin_status == 'active' ) {
						echo sprintf( '<span>%s</span> ', __( 'Active:', 'rehub_framework' ) );
					}
					echo $plugin['name'];
					?>
				</h3>
				<div class="theme-actions">
					<?php foreach( $plugin_action as $action ) { echo $action; } ?>
				</div>
				<?php if( isset( $plugin_action['update'] ) && $plugin_action['update'] ): ?>
				<div class="theme-update">Update Available: Version <?php echo $plugin['version']; ?></div>
				<?php endif; ?>
				<?php if( $plugin['required'] ): ?>
				<div class="plugin-required">
					<?php _e( 'Required', 'rehub_framework' ); ?>
				</div>
				<?php endif; ?>
			</div>
			<?php endforeach; ?>
		</div>
	</div>
	<div class="rehub-thanks">
		<p class="description"><?php echo __( "Thank you for choosing ReHub Theme. We are honored and are fully dedicated to making your experience perfect.", "rehub_framework" ); ?></p>
	</div>
</div>
<div class="wpsm-clearfix" style="clear: both;"></div>