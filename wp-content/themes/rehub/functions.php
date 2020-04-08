<?php

/** 
 * Register & enqueue styles/scripts 
 * 
 */


if(!is_admin()) add_action('init', 'rehub_framework_register_scripts');
if( !function_exists('rehub_framework_register_scripts') ) {
function rehub_framework_register_scripts() {

	// Stylesheets
	wp_register_style('style', get_stylesheet_directory_uri() . '/style.css');
	wp_register_style('responsive', get_template_directory_uri() . '/css/responsive.css');
	wp_register_style('rehub_shortcode', get_template_directory_uri() . '/shortcodes/css/css.css');
	wp_register_style('ecwid', get_template_directory_uri() . '/css/ecwid.css');
	wp_register_style('fontawesome', get_template_directory_uri() . '/vafpress-framework/public/css/vendor/font-awesome.min.css');
	wp_register_style( 'rehub-woocommerce', get_template_directory_uri().'/css/woocommerce.css' , array(), '', 'all' );
	wp_register_style('bbpress_css', get_template_directory_uri() . '/css/bbpresscustom.css');	
	wp_register_style('jquery.nouislider', get_template_directory_uri() . '/css/jquery.nouislider.css');
	wp_register_style('tabletoggle', get_template_directory_uri() . '/css/tabletoggle.css');
	wp_register_style('eggrehub', get_template_directory_uri() . '/css/eggrehub.css');

	wp_register_style('hover', get_stylesheet_directory_uri() . '/css/hover.css');


	
	//Scripts
	wp_register_script('modernizr', get_template_directory_uri() . '/js/modernizr.js', array('jquery'), '2.7.1'); // Modernizr
	wp_register_script('rehub', get_template_directory_uri() . '/js/custom.js', 'jquery', '', true);
	wp_register_script('flexslider', get_template_directory_uri() . '/js/jquery.flexslider-min.js', 'jquery', '2.2.2', true);
	wp_register_script('prettyphoto', get_template_directory_uri() . '/js/jquery.prettyPhoto.js', 'jquery', '3.1.6', true);
	wp_register_script('totemticker', get_template_directory_uri() . '/js/jquery.totemticker.js', 'jquery', '', true);
	wp_register_script('carouFredSel', get_template_directory_uri() . '/js/jquery.carouFredSel-6.2.1-packed.js', 'jquery', '6.2.1', true);
	wp_register_script('lwtCountdown', get_template_directory_uri() . '/js/jquery.lwtCountdown-1.0.js', 'jquery', '', true);
	wp_register_script('sticky', get_template_directory_uri() . '/js/jquery.sticky.js', 'jquery', '1.0.3', true);
	wp_register_script('custom_scroll', get_template_directory_uri() . '/js/custom_scroll.js', 'jquery', '1.0.0', true);
	wp_register_script('masonry', get_template_directory_uri() . '/js/masonry.pkgd.min.js', 'jquery', '3.1.5', true);
	wp_register_script('imagesloaded', get_template_directory_uri() . '/js/imagesloaded.pkgd.min.js', 'jquery', '3.1.8', true);
	wp_register_script('masonry_init', get_template_directory_uri() . '/js/masonry_init.js', 'masonry', '3.1.5', true);
	wp_register_script('infinitescroll', get_template_directory_uri() . '/js/jquery.infinitescroll.min.js', 'jquery', '2.0.2', true);
	wp_register_script('masonry_init_infauto', get_template_directory_uri() . '/js/masonry_init_infauto.js', 'jquery', '1.0.0', true);	
	wp_register_script('masonry_init_infclick', get_template_directory_uri() . '/js/masonry_init_scroll_on_click.js', 'jquery', '1.0.0', true);
	wp_register_script('jquery.nouislider', get_template_directory_uri() . '/js/jquery.nouislider.full.min.js', 'jquery', '7.0.0', true);
	wp_register_script( 'zeroclipboard', get_template_directory_uri() . '/js/zeroclipboard/ZeroClipboard.min.js', array( 'jquery' ), '2.1.6' );
	wp_register_script( 'custom_pretty', get_template_directory_uri() . '/shortcodes/js/custom_pretty.js', 'jquery', '1.0', true );
	wp_register_script('wpsm_googlemap',  get_template_directory_uri() . '/shortcodes/js/wpsm_googlemap.js', array('jquery'), '', true);
	wp_register_script('wpsm_googlemap_api', 'https://maps.googleapis.com/maps/api/js?sensor=false', array('jquery'), '', true);
	wp_register_script('tipsy', get_template_directory_uri() . '/shortcodes/js/jquery.tipsy.js', array('jquery'), '1.0.0'); // tipsy 		
	wp_register_script('tablesorter', get_template_directory_uri() . '/js/jquery.tablesorter.min.js', array('jquery'), '2.0.2'); // table sorter
	wp_register_script('touchswipe', get_template_directory_uri() . '/js/jquery.touchSwipe.min.js', array('jquery'), '2.0.5'); // swiper
	wp_register_script('affegg_coupons', get_template_directory_uri() . '/js/affegg_coupons.js', 'jquery', '1.0.0', true); // affiliate coupons
}
}

if(!is_admin()) add_action('wp_enqueue_scripts', 'rehub_enqueue_scripts');
if( !function_exists('rehub_enqueue_scripts') ) {
function rehub_enqueue_scripts() {
	if (in_array('affiliate-egg/affiliate-egg.php', apply_filters('active_plugins', get_option('active_plugins'))) || in_array('content-egg/content-egg.php', apply_filters('active_plugins', get_option('active_plugins')))) {wp_enqueue_style('eggrehub');}
	wp_enqueue_style('style');
	wp_enqueue_style('responsive');
	wp_enqueue_style('rehub_shortcode');	

	wp_enqueue_style('hover');

	wp_enqueue_style('fontawesome');
	wp_enqueue_style('default_font', '//fonts.googleapis.com/css?family=Open+Sans+Condensed:300,700&subset=latin,cyrillic');
	wp_enqueue_script('modernizr');
	wp_enqueue_script('rehub');
	if (class_exists('Woocommerce')) {wp_enqueue_style( 'rehub-woocommerce' );}
    if (class_exists('bbPress' )) {wp_enqueue_style('bbpress_css');}	
	if (rehub_option('rehub_ecwid_enable')) {wp_enqueue_style( 'ecwid' );}	
	if (rehub_option('rehub_sticky_nav')) {wp_enqueue_script( 'sticky' );}

	$translation_array = array( 
		'back' => __( 'back', 'rehub_framework' ), 
		'ajax_url' => admin_url( 'admin-ajax.php', 'relative' ),
		'templateurl' => get_template_directory_uri(),
		'fin' => __( 'That\'s all', 'rehub_framework' ),
		'your_rating' => __( 'Your Rating:', 'rehub_framework' ),
		'nonce' => wp_create_nonce('ajaxed-nonce'),
		'rating_tabs_id'   => wp_create_nonce('rating_tabs_nonce'),	  
	);
	wp_localize_script( 'rehub', 'translation', $translation_array );

	$js_vars = array( 
		'fin' => __( 'That\'s all', 'rehub_framework' ),
		'theme_url' => get_template_directory_uri(),		  
	);
	wp_localize_script( 'masonry_init_infauto', 'js_local_vars', $js_vars );
	wp_localize_script( 'masonry_init_infclick', 'js_local_vars', $js_vars );
	$affcoupons_array = array( 
		'coupontextready' => __( 'Here is your coupon code', 'rehub_framework' ), 
		'coupontextcopied' => __( 'Code is copied', 'rehub_framework' ),
		'coupongoto' => __( 'Go to ', 'rehub_framework' ),	
		'couponwebsite' => __( 'Website', 'rehub_framework' ),
		'couponuseoffer' => __( ' and use this Offer.', 'rehub_framework' ),
		'couponorcheck' => __( 'Or check your new window for opened website', 'rehub_framework' ),						  
	);		
	wp_localize_script( 'affegg_coupons', 'coupvars', $affcoupons_array );
	if (is_singular() && get_option('thread_comments'))	wp_enqueue_script('comment-reply');

}
}

// Css minify 
function rehub_quick_minify( $css ) {
	$css = preg_replace( '/\s+/', ' ', $css );
	$css = preg_replace( '/\/\*[^\!](.*?)\*\//', '', $css );
	$css = preg_replace( '/(,|:|;|\{|}) /', '$1', $css );
	$css = preg_replace( '/ (,|;|\{|})/', '$1', $css );
	$css = preg_replace( '/(:| )0\.([0-9]+)(%|em|ex|px|in|cm|mm|pt|pc)/i', '${1}.${2}${3}', $css );
	$css = preg_replace( '/(:| )(\.?)0(%|em|ex|px|in|cm|mm|pt|pc)/i', '${1}0', $css );
	return trim( $css );
}

if( !function_exists('rehub_custom_css') ) {
function rehub_custom_css() {
    return get_template_part('inc/customization');
}
}
add_action( 'wp_head', 'rehub_custom_css' );

// Add specific CSS class by filter
add_filter('body_class','width_body_names');
function width_body_names($classes) {
if (rehub_option('rehub_body_block')) $classes[] = 'block_style';	
	// return the $classes array
	return $classes;
}

/*** Other essensials ***/
if ( ! isset( $content_width ) )
	$content_width = 765;
	
add_theme_support( 'automatic-feed-links' );
add_theme_support( 'woocommerce' );
add_theme_support( 'html5', array( 'search-form' ) ); 
function rehub_title_setup() {add_theme_support( 'title-tag' );}
add_action( 'after_setup_theme', 'rehub_title_setup' );

// This theme uses its own gallery styles.
add_filter( 'use_default_gallery_style', '__return_false' );

// EDD functions
if( !function_exists('twentytwelve_edd_shortcode_atts_downloads') ) {
function twentytwelve_edd_shortcode_atts_downloads( $atts ) {
	$atts[ 'columns' ]      = '1';
	$atts[ 'full_content' ] = 'no';
	$atts[ 'excerpt' ]      = 'no';
	return $atts;
}
}
add_filter( 'shortcode_atts_downloads', 'twentytwelve_edd_shortcode_atts_downloads' );

if( !function_exists('rate_edd') ) {
function rate_edd() {
  if(rehub_option('rehub_framework_edd_rating') =='1'){
  	echo rehub_get_user_rate('user');
  } 	
}
}
add_action( 'edd_product_details_widget_before_purchase_button', 'rate_edd' );

if( !function_exists('rehub_edd_show_download_sales') ) {
function rehub_edd_show_download_sales() {
	if(rehub_option('rehub_framework_edd_counter') =='1'){
		echo '<p>';
		echo edd_get_download_sales_stats( get_the_ID() ) . ' sales';
		echo '<br/>';
		echo sumobi_edd_get_download_count( get_the_ID() ) . ' downloads';
		echo '</p>';
	}
}
}
add_action( 'edd_product_details_widget_before_purchase_button', 'rehub_edd_show_download_sales' );

if( !function_exists('sumobi_edd_get_download_count') ) { 
function sumobi_edd_get_download_count( $download_id = 0 ) {
	global $edd_logs;
	$meta_query = array(
		'relation'	=> 'AND',
		array(
			'key' => '_edd_log_file_id'
		),
		array(
			'key' => '_edd_log_payment_id'
		)
	);
	return $edd_logs->get_log_count( $download_id, 'file_download', $meta_query );
}
}



//////////////////////////////////////////////////////////////////
// Translation
//////////////////////////////////////////////////////////////////
add_action('after_setup_theme', 'rehub_theme_setup');
if( !function_exists('rehub_theme_setup') ) {
function rehub_theme_setup(){
    load_theme_textdomain('rehub_framework', get_template_directory() . '/lang');
}
}


//////////////////////////////////////////////////////////////////
// REHub Theme Options and Metaboxes
//////////////////////////////////////////////////////////////////
require_once ( locate_template( 'admin/admin.php' ) );
require_once ( locate_template( 'admin/metabox/offermeta.php' ) );
require_once ( locate_template( 'admin/rehub.php' ) );


// Here we populate the font face

$font_face_nav      = rehub_option('rehub_nav_font');
$font_face_nav_weight = rehub_option('rehub_nav_font_weight');
$font_face_nav_style  = rehub_option('rehub_nav_font_style');
$font_face_nav_subset  = rehub_option('rehub_nav_font_subset');

$font_face_headings = rehub_option('rehub_headings_font');
$font_face_headings_weight = rehub_option('rehub_headings_font_weight');
$font_face_headings_style  = rehub_option('rehub_headings_font_style');
$font_face_headings_subset  = rehub_option('rehub_headings_font_subset');

$font_face_block   = rehub_option('rehub_block_font');
$font_face_block_weight = rehub_option('rehub_block_font_weight');
$font_face_block_style  = rehub_option('rehub_block_font_style');
$font_face_block_subset  = rehub_option('rehub_block_font_subset');

$font_face_slider   = rehub_option('rehub_slider_font');
$font_face_slider_weight = rehub_option('rehub_slider_font_weight');
$font_face_slider_style  = rehub_option('rehub_slider_font_style');
$font_face_slider_subset  = rehub_option('rehub_slider_font_subset');

$font_face_body   = rehub_option('rehub_body_font');
$font_face_body_weight = rehub_option('rehub_body_font_weight');
$font_face_body_style  = rehub_option('rehub_body_font_style');
$font_face_body_subset  = rehub_option('rehub_body_font_subset');


// Add the font to the helper class
VP_Site_GoogleWebFont::instance()->add($font_face_nav, $font_face_nav_weight, $font_face_nav_style, $font_face_nav_subset);
VP_Site_GoogleWebFont::instance()->add($font_face_headings, $font_face_headings_weight, $font_face_headings_style, $font_face_headings_subset);
VP_Site_GoogleWebFont::instance()->add($font_face_block, $font_face_block_weight, $font_face_block_style, $font_face_block_subset);
VP_Site_GoogleWebFont::instance()->add($font_face_slider, $font_face_slider_weight, $font_face_slider_style, $font_face_slider_subset);
VP_Site_GoogleWebFont::instance()->add($font_face_body, $font_face_body_weight, $font_face_body_style, $font_face_body_subset);

// embed font function
function rehub_embed_fonts()
{
   VP_Site_GoogleWebFont::instance()->register_and_enqueue();
}
add_action('wp_enqueue_scripts', 'rehub_embed_fonts');

//////////////////////////////////////////////////////////////////
// Register WordPress menus
//////////////////////////////////////////////////////////////////
add_action( 'after_setup_theme', 'rehub_register_my_menus' );

if( !function_exists('rehub_register_my_menus') ) {
function rehub_register_my_menus() {
	register_nav_menus(
		array(
			'primary-menu' => __( 'Primary Menu', 'rehub_framework' ),
			'top-menu' => __( 'Top Menu', 'rehub_framework' ),
			'user_logged_in_menu' => __( 'User Logged In Menu', 'rehub_framework' ),
		)
	);
}
}


class Rehub_Walker extends Walker_Nav_Menu
{	
	function start_el(&$output, $item, $depth = 0, $args = array(), $id = 0) {
		global $wp_query;
		$indent = ( $depth ) ? str_repeat( "\t", $depth ) : '';

		$class_names = $value = '';

		$classes = empty( $item->classes ) ? array() : (array) $item->classes;

		$class_names = join( ' ', apply_filters( 'nav_menu_css_class', array_filter( $classes ), $item ) );
		$class_names = ' class="' . esc_attr( $class_names ) . '"';

		$output .= $indent . '<li id="menu-item-'. $item->ID . '"' . $value . $class_names .'>';

		$attributes  = ! empty( $item->attr_title ) ? ' title="'  . esc_attr( $item->attr_title ) .'"' : '';
		$attributes .= ! empty( $item->target )     ? ' target="' . esc_attr( $item->target     ) .'"' : '';
		$attributes .= ! empty( $item->xfn )        ? ' rel="'    . esc_attr( $item->xfn        ) .'"' : '';
		$attributes .= ! empty( $item->url )        ? ' href="'   . esc_attr( $item->url        ) .'"' : '';

		$item_output = $args->before;
		$item_output .= '<a'. $attributes .'>';
		$item_output .= $args->link_before . apply_filters( 'the_title', $item->title, $item->ID );
		$item_output .= ! empty( $item->description ) ? '<span class="subline">' . wp_trim_words($item->description, 5, '...'). '</span>' : '';
		$item_output .= $args->link_after . '</a>';
		$item_output .= $args->after;

		$output .= apply_filters( 'walker_nav_menu_start_el', $item_output, $item, $depth, $args);
	}	
}
//Add search and login to the main navigation
add_filter( 'wp_nav_menu_items', 'rehub_add_search_to_main_nav', 20, 4 );
if( ! function_exists( 'rehub_add_search_to_main_nav' ) ) {
	function rehub_add_search_to_main_nav( $items, $args ) {
		$ubermenu = false;

		if( function_exists( 'ubermenu_get_menu_instance_by_theme_location' ) && ubermenu_get_menu_instance_by_theme_location( $args->theme_location ) ) {
			// disable on ubermenu navigations
			$ubermenu = true;
		}

		if( $ubermenu == false ) {
			if($args->theme_location == 'primary-menu' && rehub_option('rehub_login_icon') == 'menu' && rehub_option('userlogin_enable') == '1') {
				$items .= '<li class="menu-item rehub-custom-menu-item rehub-top-login-onclick">';
					$items .= do_shortcode("[wpsm_user_modal wrap='a']");
				$items .= '</li>';				
			}			
			if( $args->theme_location == 'primary-menu' && rehub_option('rehub_search_icon') == 'menu' ) {
				$items .= '<li class="menu-item rehub-custom-menu-item top-search-onclick">';
					$items .= '<a class="icon-search-onclick icon-in-main-menu"></a>';
				$items .= '</li>';
			}			
		}

		return $items;
	}
}


function add_menu_for_blank(){
	echo '<nav class="top_menu"><ul class="menu"><li><a href="/wp-admin/nav-menus.php" target="_blank">Click to Add your menu</a></li></ul></nav>';
}
function add_top_menu_for_blank(){
	echo '<div class="top-nav"><ul class="menu"><li><a href="/wp-admin/nav-menus.php" target="_blank">Click to Add your menu</a></li></ul></div>';
}


//////////////////////////////////////////////////////////////////
// Resizer
//////////////////////////////////////////////////////////////////
require_once('inc/BFI_Thumb.php');
@define( BFITHUMB_UPLOAD_DIR, 'thumbs_dir');

//////////////////////////////////////////////////////////////////
// Post thumbnails
//////////////////////////////////////////////////////////////////

add_action( 'after_setup_theme', 'rehub_image_sizes' );
if ( !function_exists( 'rehub_image_sizes' ) ) {
	function rehub_image_sizes() {
		add_theme_support( 'post-thumbnails' );
		set_post_thumbnail_size( 765, 0, true );
		if( rehub_option( 'aq_resize_crop') == '1') {
			add_image_size( 'grid_news', 336, 0, false );
			add_image_size( 'feature_slider', 765, 0, false );
			add_image_size( 'med_thumbs', 123, 0, false );
			add_image_size( 'medium_news', 370, 0, false );
			add_image_size( 'news_big', 378, 0, false );
			add_image_size( 'video_big', 474, 0, false );
			add_image_size( 'video_narrow', 270, 0, false );
		}
		else {
			add_image_size( 'grid_news', 336, 220, true );
			add_image_size( 'feature_slider', 765, 460, true );
			add_image_size( 'med_thumbs', 123, 90, true );
			add_image_size( 'medium_news', 370, 220, true );
			add_image_size( 'news_big', 378, 310, true );
			add_image_size( 'video_big', 474, 342, true );
			add_image_size( 'video_narrow', 270, 110, true );
		}
	}
}


// Remove thumbnail width and height dimensions that prevent fluid images in the_thumbnail
function remove_thumbnail_dimensions( $html )
{
    $html = preg_replace( '/(width|height)=\"\d*\"\s/', "", $html );
    return $html;
}
add_filter('post_thumbnail_html', 'remove_thumbnail_dimensions', 10); // Remove width and height dynamic attributes to thumbnails
add_filter('image_send_to_editor', 'remove_thumbnail_dimensions', 10); // Remove width and height dynamic attributes to post images

//////////////////////////////////////////////////////////////////
// Get thumbnail
//////////////////////////////////////////////////////////////////
if( !function_exists('get_post_thumb') ) {
function get_post_thumb(){
	global $post ;
	if ( has_post_thumbnail($post->ID) ){
		$image_id = get_post_thumbnail_id($post->ID);  
		$image_url = wp_get_attachment_image_src($image_id,'full');  
		$image_url = $image_url[0];
		return $image_url;
	}
}
}

//////////////////////////////////////////////////////////////////
// Thumbnail function
//////////////////////////////////////////////////////////////////
if( !function_exists('wpsm_thumb') ) {
function wpsm_thumb( $size = 'small' ){
	global $post;
		if( $size == 'medium_news' ){$width = 370; $height = 220; $nothumb = get_template_directory_uri() . '/images/default/noimage_370_220.png' ;}
		elseif( $size == 'med_thumbs' ){$width = 123; $height = 90; $nothumb = get_template_directory_uri() . '/images/default/noimage_123_90.png' ;}	
		elseif( $size == 'feature_slider' ){$width = 765; $height = 460; $nothumb = get_template_directory_uri() . '/images/default/noimage_765_460.jpg' ;}
		elseif( $size == 'video_big' ){$width = 474; $height = 342; $nothumb = get_template_directory_uri() . '/images/default/noimage_474_342.png' ;}
		elseif( $size == 'video_narrow' ){$width = 270; $height = 110; $nothumb = get_template_directory_uri() . '/images/default/noimage_270_110.png' ;}
		elseif( $size == 'news_big' ){$width = 378; $height = 310; $nothumb = get_template_directory_uri() . '/images/default/noimage_378_310.png' ;}
		elseif( $size == 'grid_news' ){$width = 336; $height = 220; $nothumb = get_template_directory_uri() . '/images/default/noimage_336_220.png' ;}
		else{ $width = 123; $height = 90; $nothumb = get_template_directory_uri() . '/images/default/noimage_123_90.png' ;}	
	
	if( rehub_option( 'aq_resize') == 1 ){
		if( rehub_option( 'aq_resize_crop') == '1') {$params = array( 'width' => $width, 'quality' =>'90');}
		else {$params = array( 'width' => $width, 'height' => $height, 'crop' => true, 'quality' =>'90');}
		$img = get_post_thumb(); 
		if(!empty($img)){ ?>
			<img src="<?php echo bfi_thumb( $img, $params ); ?>" alt="<?php the_title_attribute(); ?>" />
	    <?php } elseif ((vp_metabox('rehub_post.rehub_framework_post_type') == 'video') && (vp_metabox('rehub_post.video_post.0.video_post_embed_url') !='')) {?>	
	     	<?php $img_video_url = vp_metabox('rehub_post.video_post.0.video_post_embed_url'); $img_video = parse_video_url($img_video_url, 'hqthumb');?>	
        	<img src="<?php echo $img_video ?>" alt="<?php the_title_attribute(); ?>" />
        <?php } else {?>
			<img src="<?php echo $nothumb; ?>" alt="<?php the_title_attribute(); ?>" />
		<?php }  

	}else{
		$image_id = get_post_thumbnail_id($post->ID);  
		$image_url = wp_get_attachment_image($image_id, $size , false, array( 'alt'   => get_the_title() ,'title' =>  get_the_title()  )); 
		if(!empty($image_url)){ ?>
			<?php echo $image_url; ?>
	    <?php } elseif ((vp_metabox('rehub_post.rehub_framework_post_type') == 'video') && (vp_metabox('rehub_post.video_post.0.video_post_embed_url') !='')) {?>	
	     	<?php $img_video_url = vp_metabox('rehub_post.video_post.0.video_post_embed_url'); $img_video = parse_video_url($img_video_url, 'hqthumb');?>	
        	<img src="<?php echo $img_video ?>" alt="<?php the_title_attribute(); ?>"/>
        <?php } else {?>
			<img src="<?php echo $nothumb; ?>" alt="<?php the_title_attribute(); ?>" />
		<?php } 
	}
}	
}


//////////////////////////////////////////////////////////////////
// Exclude posts
//////////////////////////////////////////////////////////////////

function rehub_exclude_feature_posts()
{						
		// check which featured area layout is activated
		if(rehub_option('rehub_featured_select') == '1') :				
				$exclude_posts_slider = rehub_option('rehub_featured_slider');
			    $exclude_posts_right = rehub_option('rehub_featured_right');
			    $exclude_posts = array_merge($exclude_posts_slider,$exclude_posts_right);
				return $exclude_posts;
				
			else :
			
				$args = array(
					'showposts' => 5,
					'meta_query' => array(
						array(
							'key' => 'is_featured',
							'value' => '1',
						)
					)
				 );
				$postslist = get_posts( $args );
				
				foreach($postslist as $post) {
					$exclude_posts[] = $post->ID;
				}
				return $exclude_posts;
		endif;

}

//////////////////////////////////////////////////////////////////
// Icons for post formats
//////////////////////////////////////////////////////////////////

if( !function_exists('rehub_price_clean') ) {
function rehub_price_clean($price) {
	$cur_clean = array('Rs.', 'руб.', 'RS.' );
	$price = str_replace($cur_clean, '', $price);
	if (rehub_option('price_pattern') == 'us') {
		$price = (float) preg_replace("/[^0-9\.]/","", $price);			
	}
	elseif (rehub_option('price_pattern') == 'eu') {
		$price = preg_replace("/[^0-9,]/","", $price);
		$price = (float) str_replace(',', '.', $price);			
	}
	elseif (rehub_option('price_pattern') == 'in') {
		$price = (float) preg_replace("/[^0-9\.]/","", $price);			
	}
	else {
		$price = (float) preg_replace("/[^0-9\.]/","", $price);
	}	
	if (!is_numeric($price) || $price =='0')	{
		return;
	}
	return $price;

}
}

if( !function_exists('rehub_formats_icons') ) {
function rehub_formats_icons($editor='no')
{

	if(vp_metabox('rehub_post.rehub_framework_post_type') == 'video') {
		echo '<span class="overlay_post_formats"><i class="fa fa-play-circle"></i></span>';
	} elseif(vp_metabox('rehub_post.rehub_framework_post_type') == 'gallery') {
		echo '<span class="overlay_post_formats review_formats_gallery"><i class="fa fa-camera"></i></span>';
	} elseif(vp_metabox('rehub_post.rehub_framework_post_type') == 'music') {
		echo '<span class="overlay_post_formats"><i class="fa fa-music"></i></span>';
	}
	elseif(vp_metabox('rehub_post.rehub_framework_post_type') == 'review') {
		$offer_url_exist = get_post_meta( get_the_ID(), 'rehub_offer_product_url', true );
		if (!empty($offer_url_exist)) {
			$offer_price = get_post_meta( get_the_ID(), 'rehub_offer_product_price', true );
		    $offer_price_old = get_post_meta(get_the_ID(), 'rehub_offer_product_price_old', true );
		}
		elseif(vp_metabox('rehub_post.review_post.0.review_post_schema_type') == 'review_post_review_product') {
			$review_aff_link = vp_metabox('rehub_post.review_post.0.review_post_product.0.review_aff_link');
			if(function_exists('thirstyInit') && !empty($review_aff_link)) {
				$linkpost = get_post($review_aff_link); 
				$offer_price = get_post_meta( $linkpost->ID, 'rehub_aff_price', true ); 
				$offer_price_old = get_post_meta( $linkpost->ID, 'rehub_aff_price_old', true );
			}
			else {
		        $offer_price = vp_metabox('rehub_post.review_post.0.review_post_product.0.review_post_product_price');
		        $offer_price_old = vp_metabox('rehub_post.review_post.0.review_post_product.0.review_post_product_price_old');				
			}	
		}
		if ( !empty($offer_price) && !empty($offer_price_old) ) {
			$offer_pricesale = rehub_price_clean($offer_price); //Clean price from currence symbols
			$offer_priceold = rehub_price_clean($offer_price_old); //Clean price from currence symbols
			if ((int)$offer_priceold !='0' && is_numeric($offer_priceold) && (int)$offer_priceold > (int)$offer_pricesale) {
				$off_proc = 0 -(100 - ((int)$offer_pricesale / (int)$offer_priceold) * 100);
				$off_proc = round($off_proc);
				echo '<span class="overlay_post_formats sale_format"><i class="fa fa-tag"></i> <span>'.$off_proc.'%</span></span>';
			}
		}			
	}	
}
}

if( !function_exists('rehub_format_score') ) {
function rehub_format_score($size = 'small', $type = 'star' )
{
	if(vp_metabox('rehub_post.rehub_framework_post_type') == 'review') {
		$overall_score_icon = rehub_get_overall_score();
		$total = $overall_score_icon * 10;
		if ($overall_score_icon !='0') {
			if ($type == 'star') {
				echo '<div class="star-'.$size.'"><span class="stars-rate"><span style="width: '.$total.'%;"></span></span></div>';
			}
			elseif ($type == 'square') {
				echo '<span class="overlay_post_formats review_formats_score">'.$overall_score_icon.'</span>';
			}
			elseif ($type == 'line') { ?>
	            <div class="rate-line rate-line-inner<?php if (rehub_option('color_type_review') == 'multicolor') {echo ' colored_rate_bar';} ?>">
                    <div class="line" data-percent="<?php echo $total;?>%"> 
                        <span class="filled r_score_<?php echo round($overall_score_icon); ?>"><?php echo $overall_score_icon ?></span>
                    </div>
                </div>
			<?php
			}			
		}	
	}
}
}

if( !function_exists('meta_all') ) {
function meta_all ($time_exist, $cats_exist, $admin_exist ){   
	if(rehub_option('exclude_date_meta') == 0 && ($time_exist != false)){ ?>
 		<span class="date"><?php the_time(get_option( 'date_format' )); ?></span>	
	<?php }
	if(rehub_option('exclude_cat_meta') == 0 && ($cats_exist != false)){ ?>
		<?php $cat_name = get_cat_name($cats_exist); ?>
		<i class="fa fa-circle"></i><a class="cat" href="<?php echo get_category_link( $cats_exist); ?>"><?php echo $cat_name ?></a>
	<?php }
	if(rehub_option('exclude_author_meta') == 0 && ($admin_exist != false)){ ?>
		<i class="fa fa-circle"></i><a class="admin" href="<?php echo get_author_posts_url( get_the_author_meta( 'ID' ) )?>"><?php echo get_the_author() ?></a>
	<?php }    	
}
}

if( !function_exists('meta_small') ) {
function meta_small ($time_exist, $cats_exist, $comm_exist, $post_views = false ){     
	if(rehub_option('exclude_date_meta') == 0 && ($time_exist != false)){ ?>
 		<span class="date"><?php the_time(get_option( 'date_format' )); ?></span>&nbsp; 	
	<?php }
	if(rehub_option('exclude_cat_meta') == 0 && ($cats_exist != false)){ ?>
		<?php $cat_name = get_cat_name($cats_exist); ?>
		<a href="<?php echo get_category_link( $cats_exist); ?>" class="cat"><?php echo $cat_name ?></a>
	<?php }
	if(rehub_option('exclude_comments_meta') == 0 && ($comm_exist != false)){ ?>
		<i class="fa fa-circle"></i> <?php comments_popup_link( __('no comments','rehub_framework'), __('1 comment','rehub_framework'), __('% comments','rehub_framework'), 'comm_meta', ''); ?>
	<?php } 
	if($post_views != false){ ?>
		<?php $rehub_views = get_post_meta (get_the_ID(),'rehub_views',true); if ($rehub_views !='') :?>
			<i class="fa fa-eye"></i> <span><?php echo $rehub_views; ?> </span>
		<?php endif ;?>
	<?php }     	   	
}
}

if( !function_exists('re_badge_create') ) {
function re_badge_create ($type = 'label' ){  
	global $post;
	$badge = get_post_meta($post->ID, 'is_editor_choice', true);
	if ($badge !='' && $badge !='0') {
		$output = '';
		$label = rehub_option('badge_label_'.$badge.'');   
		if($type =='tablelabel'){ 
			$output .= '<span class="re-line-badge re-line-table-badge badge_'.$badge.'"><span>'.$label.'</span></span>';
		}
		elseif($type =='ribbon'){ 
			$output .= '<span class="re-ribbon-badge badge_'.$badge.'"><span>'.$label.'</span></span>';
		}
		elseif($type =='ribbonleft'){ 
			$output .= '<span class="re-ribbon-badge left-badge badge_'.$badge.'"><span>'.$label.'</span></span>';
		}				
		elseif($type =='starburst'){ 
			$output .= '<span class="re-starburst badge_'.$badge.'"><span><span><span><span><span><span><span><span><strong>'.$label.'</strong></span></span></span></span></span></span></span></span></span></span>';
		}
		elseif($type =='class'){ 
			$output .= 'ed_choice_col badge_'.$badge.'';
		}
		elseif($type =='labelbig'){ 
			$output .= '<div class="text-center"><span class="re-line-badge re-line-big-label badge_'.$badge.'"><span>'.$label.'</span></span></div>';
		}				
		else{ 
			$output .= '<span class="re-line-badge badge_'.$badge.'"><span>'.$label.'</span></span>';
		}  
		return $output;		
	}
	else {
		return;
	}
   	   	
}
}


//////////////////////////////////////////////////////////////////
// Titles for custom block
//////////////////////////////////////////////////////////////////
if( !function_exists('title_custom_block') ) {
function title_custom_block ($title_enable, $title_name, $title_position, $title_url_title, $title_url_url ){

if (($title_enable) == 1) { 

	if (($title_position) == 'top_title' || ($title_position) =='') { ?>
       <div class="heading"><h5><?php echo $title_name?></h5>
         <?php if (($title_url_title) && ($title_url_url)) : ?>
         		<a href="<?php echo $title_url_url ?>"><?php echo $title_url_title ?></a>
         <?php endif; ?>
       </div>

    <?php } elseif (($title_position) == 'left_title') {?>
    	<div class="heading h-three">
    		<div class="head_section">
    	   		<div><?php echo $title_name?>
    	   		<?php if (($title_url_title) && ($title_url_url)) : ?>
         		<a href="<?php echo $title_url_url ?>"><?php echo $title_url_title ?></a>
                <?php endif; ?>
    	   		</div>
    	   </div>
    	</div> 

    <?php } else {?>
	<div class="heading h-three center">
		<div class="head_section">
	   		<div><?php echo $title_name?>
	   		<?php if (($title_url_title) && ($title_url_url)) : ?>
     		<a href="<?php echo $title_url_url ?>"><?php echo $title_url_title ?></a>
            <?php endif; ?>
	   		</div>
	   </div>
	</div> 

	<?php }	

}

}
}

//////////////////////////////////////////////////////////////////
// Get id and thumbs from youtube/vimeo url
//////////////////////////////////////////////////////////////////
if( !function_exists('parse_video_url') ) {
function parse_video_url($url,$return='embed',$width='',$height='',$rel=0){
    $urls = parse_url($url);

    //url is http://vimeo.com/xxxx
    if($urls['host'] == 'vimeo.com'){
        $vid = ltrim($urls['path'],'/');
    }
    //url is http://youtu.be/xxxx
    else if($urls['host'] == 'youtu.be'){
        $yid = ltrim($urls['path'],'/');
    }
    //url is http://www.youtube.com/embed/xxxx
    else if(strpos($urls['path'],'embed') == 1){
        $yid = end(explode('/',$urls['path']));
    }
     //url is xxxx only
    else if(strpos($url,'/')===false){
        $yid = $url;
    }
    //http://www.youtube.com/watch?feature=player_embedded&v=m-t4pcO99gI
    //url is http://www.youtube.com/watch?v=xxxx
    else{
        parse_str($urls['query']);
        $yid = $v;
        if(!empty($feature)){
            $yid = end(explode('v=',$urls['query']));
            $arr = explode('&',$yid);
            $yid = $arr[0];
        }
    }
  if(isset($yid)) {
    
    //return embed iframe
    if($return == 'embed'){
        return '<iframe width="'.($width?$width:765).'" height="'.($height?$height:430).'" src="//www.youtube.com/embed/'.$yid.'?rel='.$rel.'&enablejsapi=1" frameborder="0" ebkitAllowFullScreen mozallowfullscreen allowFullScreen></iframe>';

    }
    //return normal thumb
    else if($return == 'thumb' || $return == 'thumbmed'){
        return '//i1.ytimg.com/vi/'.$yid.'/default.jpg';
    }
    //return hqthumb
    else if($return == 'hqthumb' ){
        return '//i1.ytimg.com/vi/'.$yid.'/hqdefault.jpg';
    }
    // else return id
    else{
        return $yid;
    }
  }
  else if($vid) {
	$oembed_endpoint = 'http://vimeo.com/api/oembed';
	$json_url = $oembed_endpoint . '.json?url=' . rawurlencode($url) . '&width=765'; 
	$vimeoObject = json_decode(@file_get_contents($json_url), true); 	
  	//$vimeoObject = json_decode(@file_get_contents("//vimeo.com/api/v2/video/".$vid.".json"));
   if (!empty($vimeoObject) && $vimeoObject !== FALSE) {
      //return embed iframe
      if($return == 'embed'){
      return '<iframe width="'.($width?$width:$vimeoObject['width']).'" height="'.($height?$height:$vimeoObject['height']).'" src="//player.vimeo.com/video/'.$vid.'?title=0&byline=0&portrait=0" frameborder="0" webkitAllowFullScreen mozallowfullscreen allowFullScreen></iframe>';
    }
    //return normal thumb
    else if($return == 'thumb'){
      return $vimeoObject['thumbnail_url'];
    }
    //return medium thumb
    else if($return == 'thumbmed'){
      return str_replace('_640', '_340', $vimeoObject['thumbnail_url']);
    }
    //return hqthumb
    else if($return == 'hqthumb'){
      return $vimeoObject['thumbnail_url'];
    }
    // else return id
    else{
      return $vid;
    }
   }
  }
}
}


//////////////////////////////////////////////////////////////////
// EXCERPT
//////////////////////////////////////////////////////////////////


// Create the Custom Excerpts callback
if( !function_exists('kama_excerpt') ) {
function kama_excerpt($args=''){
	global $post;
		parse_str($args, $i);
		$maxchar 	 = isset($i['maxchar']) ?  (int)trim($i['maxchar'])		: 350;
		$text 		 = isset($i['text']) ? 			trim($i['text'])		: '';
		$save_format = isset($i['save_format']) ?	trim($i['save_format'])			: false;
		$echo		 = isset($i['echo']) ? 			false		 			: true;

	$out ='';	
	if (!$text){
		$out = $post->post_excerpt ? $post->post_excerpt : $post->post_content;
		$out = preg_replace ("~\[/?.*?\]~", '', $out ); //delete shortcodes:[singlepic id=3]
		// for <!--more-->
		//if( !$post->post_excerpt && strpos($post->post_content, '<!--more-->') ){
		//	preg_match ('/(.*)<!--more-->/s', $out, $match);
		//	$out = str_replace("\r", '', trim($match[1], "\n"));
		//	$out = preg_replace( "!\n\n+!s", "</p><p>", $out );
		//	$out = "<p>". str_replace( "\n", "<br />", $out ) ."</p>";
		//	if ($echo)
		//		return print $out;
		//	return $out;
		//}
	}

	$out = $text.$out;
	if (!$post->post_excerpt)
		$out = strip_tags($out, $save_format);

	if ( mb_strlen( $out ) > $maxchar ){
		$out = mb_substr( $out, 0, $maxchar );
		$out = preg_replace('@(.*)\s[^\s]*$@s', '\\1 ...', $out ); // убираем последнее слово, оно 99% неполное
	}	

	if($save_format){
		$out = str_replace( "\r", '', $out );
		$out = preg_replace( "!\n\n+!", "</p><p>", $out );
		$out = "<p>". str_replace ( "\n", "<br />", trim($out) ) ."</p>";
	}

	if($echo) return print $out;
	return $out;
}
}

// Create the Custom Truncate
if( !function_exists('rehub_truncate') ) {
function rehub_truncate($args=''){
		parse_str($args, $i);
		$maxchar 	 = isset($i['maxchar']) ?  (int)trim($i['maxchar'])		: 350;
		$text 		 = isset($i['text']) ? 			trim($i['text'])		: '';
		$save_format = isset($i['save_format']) ?	trim($i['save_format'])			: false;
		$echo		 = isset($i['echo']) ? 			false		 			: true;

	$out ='';	

	$out = $text.$out;

	if ( mb_strlen( $out ) > $maxchar ){
		$out = mb_substr( $out, 0, $maxchar );
		$out = preg_replace('@(.*)\s[^\s]*$@s', '\\1 ...', $out ); // убираем последнее слово, оно 99% неполное
	}	

	if($save_format){
		$out = str_replace( "\r", '', $out );
		$out = preg_replace( "!\n\n+!", "</p><p>", $out );
		$out = "<p>". str_replace ( "\n", "<br />", trim($out) ) ."</p>";
	}

	if($echo) return print $out;
	return $out;
}
}

// login shortcode
if(!function_exists('wpsm_login_page')) {
function wpsm_login_page( $atts, $content = null ) {
	ob_start(); 
	rehub_login_form();
	$output = ob_get_contents();
	ob_end_clean();
	return $output; 
}
add_shortcode('wpsm_login_form', 'wpsm_login_page');
}


//////////////////////////////////////////////////////////////////
// POST VIEW FUNCTION
//////////////////////////////////////////////////////////////////

add_action('wp_enqueue_scripts', 'rehub_postview_enqueue');
function rehub_postview_enqueue() {
	global $post;
	if ( is_single()) {
		if (rehub_option('post_view_disable') !='1') {
			wp_register_script( 'rehub-postview', get_template_directory_uri() . '/js/postviews.js', array( 'jquery' ) );
			wp_localize_script( 'rehub-postview', 'postviewvar', array('admin_ajax_url' => admin_url('admin-ajax.php', (is_ssl() ? 'https' : 'http')), 'post_id' => intval($post->ID)));
			wp_enqueue_script ( 'rehub-postview');
		}
	}
}

// Ajax function for count views
add_action('wp_ajax_rehubpostviews', 'rehub_increment_views');
add_action('wp_ajax_nopriv_rehubpostviews', 'rehub_increment_views');
function rehub_increment_views() {
	global $wpdb;
	if(!empty($_GET['postviews_id']) )
	{
		$post_id = intval($_GET['postviews_id']);
		if($post_id > 0 ) {
			$count = 0;
			$count_key = 'rehub_views';
			$count = (int)get_post_meta($post_id, $count_key, true);

			$count++;
			update_post_meta($post_id, $count_key, (int)$count);

			echo $count;
		}
	}
	exit();
}


//////////////////////////////////////////////////////////////////
// ADD REVIEW FUNCTIONS
//////////////////////////////////////////////////////////////////
if (rehub_option('type_user_review') == 'user') {include (TEMPLATEPATH . '/functions/user_review_no_editor.php');}
include (TEMPLATEPATH . '/functions/review_functions.php');
if (rehub_option('type_user_review') == 'full_review' || rehub_option('type_user_review') == 'user') {include (TEMPLATEPATH . '/functions/user_review_functions.php');}
if ((rehub_option('type_user_review') == 'full_review' || rehub_option('type_user_review') == 'user') && rehub_option('enable_btn_userreview') == '1') {include (TEMPLATEPATH . '/functions/commentplus.php');}

//////////////////////////////////////////////////////////////////
// COMMENTS LAYOUT
//////////////////////////////////////////////////////////////////

if( !function_exists('rehub_framework_comments') ) {
function rehub_framework_comments($comment, $args, $depth) {
	$GLOBALS['comment'] = $comment;		
	?>
	<li <?php comment_class(); ?> id="comment-<?php comment_ID() ?>">
		<div class="commbox">
			<div class="comment-author vcard clearfix">
            	<?php edit_comment_link(__('Edit', 'rehub_framework')); ?>
				<?php comment_reply_link(array_merge( $args, array('reply_text' => __(' Reply', 'rehub_framework'), 'depth' => $depth, 'max_depth' => $args['max_depth'])), $comment->comment_ID); ?>                    
				<?php echo get_avatar($comment,$args['avatar_size']); ?>
				<span class="fn"><?php echo get_comment_author_link(); ?></span>
				<span class="time"><?php printf(__('%1$s at %2$s', 'rehub_framework'), get_comment_date(),  get_comment_time()) ?></span>
                <?php if ($comment->comment_approved == '0') : ?><div class="ap_waiting"><em><?php _e('Comment awaiting for approval', 'rehub_framework'); ?></em></div><?php endif; ?>					
			</div>
			<?php if (rehub_option('type_user_review') == 'full_review' || rehub_option('type_user_review') == 'user') :?>               
	          	<?php $userCriteria = get_comment_meta(get_comment_ID(), 'user_criteria', true);
				if(is_array($userCriteria) && !empty($userCriteria)) :?> 
	              <div class="comment-content-withreview">
	                   <?php attach_comment_criteria_raitings () ;?>
	              </div>   
	     		<?php else :?>
	               <div class="comment-content"><?php comment_text(); ?></div>
				<?php endif; ?>
	     	<?php else :?>
	            <div class="comment-content"><?php comment_text(); ?></div>
			<?php endif; ?>			 
		</div>
	<?php 
}
}



//////////////////////////////////////////////////////////////////
// Category custom fields
//////////////////////////////////////////////////////////////////

add_action('admin_init', 'category_custom_fields', 1);
if( !function_exists('category_custom_fields') ) {
function category_custom_fields()
    {
        add_action('edit_category_form_fields', 'category_custom_fields_form');
        add_action('edited_category', 'category_custom_fields_save');
        add_action( 'create_category', 'category_custom_fields_save'); 
        add_action( 'category_add_form_fields', 'category_custom_fields_form_new');

    }
}    

if( !function_exists('category_custom_fields_form') ) {
function category_custom_fields_form($tag)
    {
        $t_id = $tag->term_id;
        $cat_meta = get_option("category_$t_id");
        wp_enqueue_script('wp-color-picker');
        wp_enqueue_style( 'wp-color-picker' );
?>
        <tr class="form-field color_cat_grade">
        	<th scope="row" valign="top"><label><?php _e('Cat color','rehub_framework'); ?></label></th>
        	<td>
        		<input type="text" name="Cat_meta[cat_color]" id="Cat_meta[cat_color]" size="25" style="width:60%;" value="<?php echo (!empty($cat_meta['cat_color'])) ? $cat_meta['cat_color'] : ''; ?>" data-default-color="#E43917"><br />
	            <script type="text/javascript">
	    			jQuery(document).ready(function($) {   
	        			$('.color_cat_grade input').wpColorPicker();
	    			});             
	    		</script>
                <span class="description"><?php _e('Set category color. Note, this color will be used under white text','rehub_framework'); ?></span>
            </td>
        </tr> 
        <tr class="form-field">
        	<th scope="row" valign="top"><label><?php _e('Category banner custom html','rehub_framework'); ?></label></th>
        	<td>
        		<input type="text" name="Cat_meta[cat_image_url]" id="Cat_meta[cat_image_url]" size="25" style="width:60%;" value="<?php echo (!empty($cat_meta['cat_image_url'])) ? $cat_meta['cat_image_url'] : ''; ?>"><br />
                <span class="description"><?php _e('Set url to image of banner or any custom html, shortcode','rehub_framework'); ?></span>
            </td>
        </tr>          
<?php
    }
}    

if( !function_exists('category_custom_fields_form_new') ) {
function category_custom_fields_form_new($tag)
    {
        $t_id = $tag->term_id;
        $cat_meta = get_option("category_$t_id");
        wp_enqueue_script('wp-color-picker');
        wp_enqueue_style( 'wp-color-picker' );
?>
        <div class="form-field color_cat_grade">
        	<label><?php _e('Cat color','rehub_framework'); ?></label>        	
        		<input type="text" name="Cat_meta[cat_color]" id="Cat_meta[cat_color]" size="25" style="width:60%;" value="<?php echo (!empty($cat_meta['cat_color'])) ? $cat_meta['cat_color'] : ''; ?>" data-default-color="#E43917"><br />
	            <script type="text/javascript">
	    			jQuery(document).ready(function($) {   
	        			$('.color_cat_grade input').wpColorPicker();
	    			});             
	    		</script>
                <span class="description"><?php _e('Set category color. Note, this color will be used under white text','rehub_framework'); ?></span> 
        </div> 
        <div class="form-field">
        	<label><?php _e('Category banner custom html','rehub_framework'); ?></label>
        		<input type="text" name="Cat_meta[cat_image_url]" id="Cat_meta[cat_image_url]" size="25" style="width:60%;" value="<?php echo (!empty($cat_meta['cat_image_url'])) ? $cat_meta['cat_image_url'] : ''; ?>"><br />
                <span class="description"><?php _e('Set url to image of banner or any custom html, shortcode','rehub_framework'); ?></span>     
        </div>         
<?php
    }    
}

if( !function_exists('category_custom_fields_save') ) {    
function category_custom_fields_save($term_id)
    {
        if (isset($_POST['Cat_meta'])) {
            $t_id = $term_id;
            $cat_meta = get_option("category_$t_id");
            $cat_keys = array_keys($_POST['Cat_meta']);
            foreach ($cat_keys as $key) {
                if (isset($_POST['Cat_meta'][$key])) {
                    $cat_meta[$key] = $_POST['Cat_meta'][$key];
                }
            }
            //save the option array
            update_option("category_$t_id", $cat_meta);
        }
    }
}    

// A callback function to add a custom field to our "presenters" taxonomy 
if( !function_exists('shopimage_taxonomy_custom_fields') ) { 
function shopimage_taxonomy_custom_fields($tag) {  
   // Check for existing taxonomy meta for the term you're editing  
    $t_id = $tag->term_id; // Get the ID of the term you're editing  
    $term_meta = get_option( "taxonomy_term_$t_id" ); // Do the check  
?>  
  
<tr class="form-field">  
    <th scope="row" valign="top">  
        <label for="brand_image"><?php _e('Shop image', 'rehub_framework'); ?></label>  
    </th>  
    <td>  
        <input type="text" name="term_meta[brand_image]" id="term_meta[brand_image]" size="25" style="width:60%;" value="<?php echo $term_meta['brand_image'] ? $term_meta['brand_image'] : ''; ?>"><br />  
        <span class="description"><?php _e('Add url to default image of affiliate shop', 'rehub_framework'); ?></span>  
    </td>  
</tr>  
  
<?php  
} 
}

// A callback function to add a custom field to our "presenters" taxonomy 
if( !function_exists('shopimage_taxonomy_custom_fields_new') ) { 
function shopimage_taxonomy_custom_fields_new($tag) {  
   // Check for existing taxonomy meta for the term you're editing  
    $t_id = $tag->term_id; // Get the ID of the term you're editing  
    $term_meta = get_option( "taxonomy_term_$t_id" ); // Do the check  
?>  
  
<div class="form-field">  
        <label for="brand_image"><?php _e('Shop image', 'rehub_framework'); ?></label>  
        <input type="text" name="term_meta[brand_image]" id="term_meta[brand_image]" size="25" style="width:60%;" value="<?php echo $term_meta['brand_image'] ? $term_meta['brand_image'] : ''; ?>"><br />  
        <span class="description"><?php _e('Add url to default image of affiliate shop', 'rehub_framework'); ?></span>   
</div>  
  
<?php  
}  
}

// A callback function to save our extra taxonomy field(s) 
if( !function_exists('rehub_save_taxonomy_custom_fields') ) { 
function rehub_save_taxonomy_custom_fields( $term_id ) {  
    if ( isset( $_POST['term_meta'] ) ) {  
        $t_id = $term_id;  
        $term_meta = get_option( "taxonomy_term_$t_id" );  
        $cat_keys = array_keys( $_POST['term_meta'] );  
            foreach ( $cat_keys as $key ){  
            if ( isset( $_POST['term_meta'][$key] ) ){  
                $term_meta[$key] = $_POST['term_meta'][$key];  
            }  
        }  
        //save the option array  
        update_option( "taxonomy_term_$t_id", $term_meta );  
    }  
} 
}


if(function_exists('thirstyInit')) { add_action('admin_init', 'aff_cat_custom_fields', 1);}
if( !function_exists('aff_cat_custom_fields') ) {
function aff_cat_custom_fields() {    
    // Add the fields to the "presenters" taxonomy, using our callback function  
	add_action( 'thirstylink-category_edit_form_fields', 'shopimage_taxonomy_custom_fields', 10, 2 );  
    // Save the changes made on the "presenters" taxonomy, using our callback function  
	add_action( 'edited_thirstylink-category', 'rehub_save_taxonomy_custom_fields', 10, 2 ); 
    add_action( 'create_thirstylink-category', 'rehub_save_taxonomy_custom_fields'); 
    add_action( 'thirstylink-category_add_form_fields', 'shopimage_taxonomy_custom_fields_new');
}
}

if ( in_array( 'woocommerce/woocommerce.php', apply_filters( 'active_plugins', get_option( 'active_plugins' ) ) ) ) {
	add_action('admin_init', 'woo_tag_custom_fields', 1);
}
if( !function_exists('woo_tag_custom_fields') ) {
function woo_tag_custom_fields() {    
    // Add the fields to the "presenters" taxonomy, using our callback function  
	add_action( 'product_tag_edit_form_fields', 'shopimage_taxonomy_custom_fields', 10, 2 );  
    // Save the changes made on the "presenters" taxonomy, using our callback function  
	add_action( 'edited_product_tag', 'rehub_save_taxonomy_custom_fields', 10, 2 ); 
    add_action( 'create_product_tag', 'rehub_save_taxonomy_custom_fields'); 
    add_action( 'product_tag_add_form_fields', 'shopimage_taxonomy_custom_fields_new');
}
}	


//////////////////////////////////////////////////////////////////
// Pagination
//////////////////////////////////////////////////////////////////

if( !function_exists('rehub_pagination') ) {
function rehub_pagination() {

	if( is_singular() )
		return;
	global $paged;
	global $wp_query;

	/** Stop execution if there's only 1 page */
	if( $wp_query->max_num_pages <= 1 )
		return;

	$paged = get_query_var( 'paged' ) ? absint( get_query_var( 'paged' ) ) : 1;
	$max   = intval( $wp_query->max_num_pages );

	/**	Add current page to the array */
	if ( $paged >= 1 )
		$links[] = $paged;

	/**	Add the pages around the current page to the array */
	if ( $paged >= 3 ) {
		$links[] = $paged - 1;
		$links[] = $paged - 2;
	}

	if ( ( $paged + 2 ) <= $max ) {
		$links[] = $paged + 2;
		$links[] = $paged + 1;
	}

	echo '<ul class="page-numbers">' . "\n";

	/**	Previous Post Link */
	if ( get_previous_posts_link() )
		printf( '<li class="prev_paginate_link">%s</li>' . "\n", get_previous_posts_link() );

	/**	Link to first page, plus ellipses if necessary */
	if ( ! in_array( 1, $links ) ) {
		$class = 1 == $paged ? ' class="active"' : '';

		printf( '<li%s><a href="%s">%s</a></li>' . "\n", $class, esc_url( get_pagenum_link( 1 ) ), '1' );

		if ( ! in_array( 2, $links ) )
			echo '<li class="hellip_paginate_link">&hellip;</li>';
	}

	/**	Link to current page, plus 2 pages in either direction if necessary */
	sort( $links );
	foreach ( (array) $links as $link ) {
		$class = $paged == $link ? ' class="active"' : '';
		printf( '<li%s><a href="%s">%s</a></li>' . "\n", $class, esc_url( get_pagenum_link( $link ) ), $link );
	}

	/**	Link to last page, plus ellipses if necessary */
	if ( ! in_array( $max, $links ) ) {
		if ( ! in_array( $max - 1, $links ) )
			echo '<li class="hellip_paginate_link">&hellip;</li>' . "\n";

		$class = $paged == $max ? ' class="active"' : '';
		printf( '<li%s><a href="%s">%s</a></li>' . "\n", $class, esc_url( get_pagenum_link( $max ) ), $max );
	}

	/**	Next Post Link */
	if ( get_next_posts_link() )
		printf( '<li class="next_paginate_link">%s</li>' . "\n", get_next_posts_link() );

	echo '</ul>' . "\n";

}
}


//////////////////////////////////////////////////////////////////
// Breadcrumbs
//////////////////////////////////////////////////////////////////

if( !function_exists('dimox_breadcrumbs') ) {
function dimox_breadcrumbs() {

  /* === OPTIONS === */
  $text['home'] = __('Home', 'rehub_framework');
  $text['category'] = __('Archive category "%s"', 'rehub_framework');
  $text['search'] = __('Search results for "%s"', 'rehub_framework');
  $text['tag'] = __('Posts with tag "%s"', 'rehub_framework');
  $text['author'] = __('Author archive "%s"', 'rehub_framework');
  $text['404'] = __('Error 404', 'rehub_framework');

  $show_current = 1; // 1 - show current name of article
  $show_on_home = 0; 
  $show_home_link = 1; // 1 - show link to Home page
  $show_title = 1; // 1 - show titles for links
  $delimiter = ' &raquo; '; // delimiter
  $before = '<span class="current">'; // tag before current 
  $after = '</span>'; // tag after current

  global $post;
  $home_link = home_url('/');
  $link_before = '<span typeof="v:Breadcrumb">';
  $link_after = '</span>';
  $link_attr = ' rel="v:url" property="v:title"';
  $link = $link_before . '<a' . $link_attr . ' href="%1$s">%2$s</a>' . $link_after;
  $parent_id = $parent_id_2 = $post->post_parent;
  $frontpage_id = get_option('page_on_front');

  if (is_home() || is_front_page()) {

    if ($show_on_home == 1) echo '<div class="breadcrumb"><a href="' . $home_link . '">' . $text['home'] . '</a></div>';

  } else {
    echo '<div class="breadcrumb" xmlns:v="http://rdf.data-vocabulary.org/#">';
    if ($show_home_link == 1) {
      echo '<a href="' . $home_link . '" rel="v:url" property="v:title">' . $text['home'] . '</a>';
      if ($frontpage_id == 0 || $parent_id != $frontpage_id) echo $delimiter;
    }
    if ( is_category() ) {
      $this_cat = get_category(get_query_var('cat'), false);
      if ($this_cat->parent != 0) {
        $cats = get_category_parents($this_cat->parent, TRUE, $delimiter);
        if ($show_current == 0) $cats = preg_replace("#^(.+)$delimiter$#", "$1", $cats);
        $cats = str_replace('<a', $link_before . '<a' . $link_attr, $cats);
        $cats = str_replace('</a>', '</a>' . $link_after, $cats);
        if ($show_title == 0) $cats = preg_replace('/ title="(.*?)"/', '', $cats);
        echo $cats;
      }
      if ($show_current == 1) echo $before . sprintf($text['category'], single_cat_title('', false)) . $after;
    } elseif ( is_search() ) {
      echo $before . sprintf($text['search'], get_search_query()) . $after;
    } elseif ( is_day() ) {
      echo sprintf($link, get_year_link(get_the_time('Y')), get_the_time('Y')) . $delimiter;
      echo sprintf($link, get_month_link(get_the_time('Y'),get_the_time('m')), get_the_time('F')) . $delimiter;
      echo $before . get_the_time('d') . $after;
    } elseif ( is_month() ) {
      echo sprintf($link, get_year_link(get_the_time('Y')), get_the_time('Y')) . $delimiter;
      echo $before . get_the_time('F') . $after;
    } elseif ( is_year() ) {
      echo $before . get_the_time('Y') . $after;
    } elseif ( is_single() && !is_attachment() ) {
      if ( get_post_type() != 'post' ) {
        $post_type = get_post_type_object(get_post_type());
        $slug = $post_type->rewrite;
        printf($link, $home_link . $slug['slug'] . '/', $post_type->labels->singular_name);
        if ($show_current == 1) echo $delimiter . $before . get_the_title() . $after;
      } else {
        $cat = get_the_category(); $cat = $cat[0];
        $cats = get_category_parents($cat, TRUE, $delimiter);
        if ($show_current == 0) $cats = preg_replace("#^(.+)$delimiter$#", "$1", $cats);
        $cats = str_replace('<a', $link_before . '<a' . $link_attr, $cats);
        $cats = str_replace('</a>', '</a>' . $link_after, $cats);
        if ($show_title == 0) $cats = preg_replace('/ title="(.*?)"/', '', $cats);
        echo $cats;
        if ($show_current == 1) echo $before . get_the_title() . $after;
      }
    } elseif ( !is_single() && !is_page() && get_post_type() != 'post' && !is_404() ) {
      $post_type = get_post_type_object(get_post_type());
      echo $before . $post_type->labels->singular_name . $after;
    } elseif ( is_attachment() ) {
      $parent = get_post($parent_id);
      $cat = get_the_category($parent->ID); $cat = $cat[0];
      if ($cat) {
        $cats = get_category_parents($cat, TRUE, $delimiter);
        $cats = str_replace('<a', $link_before . '<a' . $link_attr, $cats);
        $cats = str_replace('</a>', '</a>' . $link_after, $cats);
        if ($show_title == 0) $cats = preg_replace('/ title="(.*?)"/', '', $cats);
        echo $cats;
      }
      printf($link, get_permalink($parent), $parent->post_title);
      if ($show_current == 1) echo $delimiter . $before . get_the_title() . $after;

    } elseif ( is_page() && !$parent_id ) {
      if ($show_current == 1) echo $before . get_the_title() . $after;
    } elseif ( is_page() && $parent_id ) {
      if ($parent_id != $frontpage_id) {
        $breadcrumbs = array();
        while ($parent_id) {
          $page = get_page($parent_id);
          if ($parent_id != $frontpage_id) {
            $breadcrumbs[] = sprintf($link, get_permalink($page->ID), get_the_title($page->ID));
          }
          $parent_id = $page->post_parent;
        }
        $breadcrumbs = array_reverse($breadcrumbs);
        for ($i = 0; $i < count($breadcrumbs); $i++) {
          echo $breadcrumbs[$i];
          if ($i != count($breadcrumbs)-1) echo $delimiter;
        }
      }
      if ($show_current == 1) {
        if ($show_home_link == 1 || ($parent_id_2 != 0 && $parent_id_2 != $frontpage_id)) echo $delimiter;
        echo $before . get_the_title() . $after;
      }
    } elseif ( is_tag() ) {
      echo $before . sprintf($text['tag'], single_tag_title('', false)) . $after;
    } elseif ( is_author() ) {
   		global $author;
      $userdata = get_userdata($author);
      echo $before . sprintf($text['author'], $userdata->display_name) . $after;
    } elseif ( is_404() ) {
      echo $before . $text['404'] . $after;
    } elseif ( has_post_format() && !is_singular() ) {
      echo get_post_format_string( get_post_format() );
    }
    if ( get_query_var('paged') ) {
      if ( is_category() || is_day() || is_month() || is_year() || is_search() || is_tag() || is_author() ) echo ' (';
      echo 'Страница ' . get_query_var('paged');
      if ( is_category() || is_day() || is_month() || is_year() || is_search() || is_tag() || is_author() ) echo ')';
    }
    echo '</div><!-- .breadcrumbs -->';
  }
} // end dimox_breadcrumbs()
}


//////////////////////////////////////////////////////////////////
// AUTHOR SOCIAL LINKS
//////////////////////////////////////////////////////////////////
function rehub_contactmethods( $contactmethods ) {

	$contactmethods['twitter']   = __('Url of Twitter page', 'rehub_framework');
	$contactmethods['facebook']  = __('Url of Facebook page', 'rehub_framework');
	$contactmethods['google']    = __('Url of Google Plus page', 'rehub_framework');
	$contactmethods['tumblr']    = __('Url of Tumblr page', 'rehub_framework');
	$contactmethods['instagram'] = __('Url of Instagram page', 'rehub_framework');
	$contactmethods['vkontakte'] = __('Url of Vk.com page', 'rehub_framework');
	$contactmethods['youtube'] = __('Url of Youtube page', 'rehub_framework');

	return $contactmethods;
}
add_filter('user_contactmethods','rehub_contactmethods',10,1);


//add widget sidebar functions
include (TEMPLATEPATH . '/functions/sidebar_functions.php');

//add woocommerce functions
if ( in_array( 'woocommerce/woocommerce.php', apply_filters( 'active_plugins', get_option( 'active_plugins' ) ) ) ) {
include (TEMPLATEPATH . '/functions/woo_functions.php');
}

//add shortcode functions
include (TEMPLATEPATH . '/shortcodes/shortcodes.php');



//////////////////////////////////////////////////////////////////
// Helper Functions
//////////////////////////////////////////////////////////////////

function rehub_kses($html)
{
	$allow = array_merge(wp_kses_allowed_html( 'post' ), array(
		'link' => array(
			'href'    => true,
			'rel'     => true,
			'type'    => true,
		),
		'script' => array(
			'src' => true,
			'charset' => true,
			'type'    => true,
		),
		'div' => array(
			'data-href' => true,
			'data-width' => true,
			'data-numposts'    => true,
			'data-colorscheme'    => true,
			'class' => true,
			'id' => true,
			'style' => true,
			'title' => true,
			'role' => true,
			'align' => true,
			'dir' => true,
			'lang' => true,
			'xml:lang' => true,			
		)
	));
	return wp_kses($html, $allow);
}


/**
 * This file represents an example of the code that themes would use to register
 * the required plugins.
 *
 * It is expected that theme authors would copy and paste this code into their
 * functions.php file, and amend to suit.
 *
 * @package    TGM-Plugin-Activation
 * @subpackage Example
 * @version    2.4.0
 * @author     Thomas Griffin <thomasgriffinmedia.com>
 * @author     Gary Jones <gamajo.com>
 * @copyright  Copyright (c) 2014, Thomas Griffin
 * @license    http://opensource.org/licenses/gpl-2.0.php GPL v2 or later
 * @link       https://github.com/thomasgriffin/TGM-Plugin-Activation
 */

/**
 * Include the TGM_Plugin_Activation class.
 */
require_once dirname( __FILE__ ) . '/class-tgm-plugin-activation.php';

add_action( 'tgmpa_register', 'my_theme_register_required_plugins' );
/**
 * Register the required plugins for this theme.
 *
 * In this example, we register two plugins - one included with the TGMPA library
 * and one from the .org repo.
 *
 * The variable passed to tgmpa_register_plugins() should be an array of plugin
 * arrays.
 *
 * This function is hooked into tgmpa_init, which is fired within the
 * TGM_Plugin_Activation class constructor.
 */
if( !function_exists('my_theme_register_required_plugins') ) {
function my_theme_register_required_plugins() {

    /**
     * Array of plugin arrays. Required keys are name and slug.
     * If the source is NOT from the .org repo, then source is also required.
     */
    $plugins = array(

		array(
			'name'     				=> 'Envato Market', // The plugin name
			'slug'     				=> 'envato-market', // The plugin slug (typically the folder name)
			'source'   				=> get_template_directory() . '/plugins/envato-market.zip', // The plugin source
			'required' 				=> false, // If false, the plugin is only 'recommended' instead of required
			'version' 				=> '', // E.g. 1.0.0. If set, the active plugin must be this version or higher, otherwise a notice is presented
			'force_activation' 		=> false, // If true, plugin is activated upon theme activation and cannot be deactivated until theme switch
			'force_deactivation' 	=> false, // If true, plugin is deactivated upon theme switch, useful for theme-specific plugins
			'external_url' 			=> '', // If set, overrides default API URL and points to an external URL
			'image_url'          	=> get_template_directory_uri() . '/admin/screens/images/envato.jpg',			
			'description'			=> 'Auto update of theme',
		),

		array(
			'name'     				=> 'Visual Composer', // The plugin name
			'slug'     				=> 'js_composer', // The plugin slug (typically the folder name)
			'source'   				=> get_template_directory() . '/plugins/js_composer.zip', // The plugin source
			'required' 				=> false, // If false, the plugin is only 'recommended' instead of required
			'version' 				=> '', // E.g. 1.0.0. If set, the active plugin must be this version or higher, otherwise a notice is presented
			'force_activation' 		=> false, // If true, plugin is activated upon theme activation and cannot be deactivated until theme switch
			'force_deactivation' 	=> false, // If true, plugin is deactivated upon theme switch, useful for theme-specific plugins
			'external_url' 			=> '', // If set, overrides default API URL and points to an external URL
			'image_url'          	=> get_template_directory_uri() . '/admin/screens/images/vcomposer.png',			
			'description'			=> 'Enhanced layout builder',
		),	

		array(
			'name'      => 'Content EGG',
			'slug'      => 'content-egg',
			'required'  => false,
			'image_url'          => get_template_directory_uri() . '/admin/screens/images/contentegg.png',
			'description'			=> 'All in one for moneymaking',			
		),	

		array(
			'name'     				=> 'MDTF', // The plugin name
			'slug'     				=> 'meta-data-filter', // The plugin slug (typically the folder name)
			'source'   				=> get_template_directory() . '/plugins/meta-data-filter.zip', // The plugin source
			'required' 				=> false, // If false, the plugin is only 'recommended' instead of required
			'version' 				=> '', // E.g. 1.0.0. If set, the active plugin must be this version or higher, otherwise a notice is presented
			'force_activation' 		=> false, // If true, plugin is activated upon theme activation and cannot be deactivated until theme switch
			'force_deactivation' 	=> false, // If true, plugin is deactivated upon theme switch, useful for theme-specific plugins
			'external_url' 			=> '', // If set, overrides default API URL and points to an external URL
			'image_url'          => get_template_directory_uri() . '/admin/screens/images/mdtf.png',			
			'description'			=> 'Search filters and specification',			
		),			

		array(
			'name'     				=> 'Accesspress PRO', // The plugin name
			'slug'     				=> 'accesspress-anonymous-post-pro', // The plugin slug (typically the folder name)
			'source'   				=> get_template_directory() . '/plugins/accesspress-anonymous-post-pro.zip', // The plugin source
			'required' 				=> false, // If false, the plugin is only 'recommended' instead of required
			'version' 				=> '', // E.g. 1.0.0. If set, the active plugin must be this version or higher, otherwise a notice is presented
			'force_activation' 		=> false, // If true, plugin is activated upon theme activation and cannot be deactivated until theme switch
			'force_deactivation' 	=> false, // If true, plugin is deactivated upon theme switch, useful for theme-specific plugins
			'external_url' 			=> '', // If set, overrides default API URL and points to an external URL
			'description'			=> 'For creating frontend submit forms',
			'image_url'          => get_template_directory_uri() . '/admin/screens/images/accesspress.png',						
		),			

		array(
			'name'     				=> 'WPSM Table Maker', // The plugin name
			'slug'     				=> 'table-maker', // The plugin slug (typically the folder name)
			'required' 				=> false, // If false, the plugin is only 'recommended' instead of required
			'image_url'          => get_template_directory_uri() . '/admin/screens/images/tablemaker.png',
			'description'			=> 'Creating comparison static tables',						
		),

		array(
			'name'     				=> 'WooSidebars', // The plugin name
			'slug'     				=> 'woosidebars', // The plugin slug (typically the folder name)
			'required' 				=> false, // If false, the plugin is only 'recommended' instead of required
			'description'			=> 'For custom WooCommerce sidebars',
			'image_url'          	=> get_template_directory_uri() . '/admin/screens/images/woosidebars.png',			
		),					

    );

    /**
     * Array of configuration settings. Amend each line as needed.
     * If you want the default strings to be available under your own theme domain,
     * leave the strings uncommented.
     * Some of the strings are added into a sprintf, so see the comments at the
     * end of each line for what each argument will be.
     */
    $config = array(
        'id'           => 'rehub_framework',                 // Unique ID for hashing notices for multiple instances of TGMPA.
        'default_path' => '',                      // Default absolute path to pre-packaged plugins.
        'menu'         => 'tgmpa-install-plugins', // Menu slug.
        'has_notices'  => true,                    // Show admin notices or not.
        'dismissable'  => true,                    // If false, a user cannot dismiss the nag message.
        'dismiss_msg'  => '',                      // If 'dismissable' is false, this message will be output at top of nag.
        'is_automatic' => false,                   // Automatically activate plugins after installation or not.
        'message'      => '',                      // Message to output right before the plugins table.
        'strings'      => array(
            'page_title'                      => __( 'Install Required Plugins', 'rehub_framework' ),
            'menu_title'                      => __( 'Install Plugins', 'rehub_framework' ),
            'installing'                      => __( 'Installing Plugin: %s', 'rehub_framework' ), // %s = plugin name.
            'oops'                            => __( 'Something went wrong with the plugin API.', 'rehub_framework' ),
            'notice_can_install_required'     => _n_noop( 'This theme requires the following plugin: %1$s.', 'This theme requires the following plugins: %1$s.', 'rehub_framework' ), // %1$s = plugin name(s).
            'notice_can_install_recommended'  => _n_noop( 'This theme recommends the following plugin: %1$s.', 'This theme recommends the following plugins: %1$s. Please, activate only those plug-ins which are necessary to you', 'rehub_framework' ), // %1$s = plugin name(s).
            'notice_cannot_install'           => _n_noop( 'Sorry, but you do not have the correct permissions to install the %s plugin. Contact the administrator of this site for help on getting the plugin installed.', 'Sorry, but you do not have the correct permissions to install the %s plugins. Contact the administrator of this site for help on getting the plugins installed.', 'rehub_framework' ), // %1$s = plugin name(s).
            'notice_can_activate_required'    => _n_noop( 'The following required plugin is currently inactive: %1$s.', 'The following required plugins are currently inactive: %1$s.', 'rehub_framework' ), // %1$s = plugin name(s).
            'notice_can_activate_recommended' => _n_noop( 'The following recommended plugin is currently inactive: %1$s.', 'The following recommended plugins are currently inactive: %1$s.', 'rehub_framework' ), // %1$s = plugin name(s).
            'notice_cannot_activate'          => _n_noop( 'Sorry, but you do not have the correct permissions to activate the %s plugin. Contact the administrator of this site for help on getting the plugin activated.', 'Sorry, but you do not have the correct permissions to activate the %s plugins. Contact the administrator of this site for help on getting the plugins activated.', 'rehub_framework' ), // %1$s = plugin name(s).
            'notice_ask_to_update'            => _n_noop( 'The following plugin needs to be updated to its latest version to ensure maximum compatibility with this theme: %1$s.', 'The following plugins need to be updated to their latest version to ensure maximum compatibility with this theme: %1$s.', 'rehub_framework' ), // %1$s = plugin name(s).
            'notice_cannot_update'            => _n_noop( 'Sorry, but you do not have the correct permissions to update the %s plugin. Contact the administrator of this site for help on getting the plugin updated.', 'Sorry, but you do not have the correct permissions to update the %s plugins. Contact the administrator of this site for help on getting the plugins updated.', 'rehub_framework' ), // %1$s = plugin name(s).
            'install_link'                    => _n_noop( 'Begin installing plugin', 'Begin installing plugins', 'rehub_framework' ),
            'activate_link'                   => _n_noop( 'Begin activating plugin', 'Begin activating plugins', 'rehub_framework' ),
            'return'                          => __( 'Return to Required Plugins Installer and Activate plugins', 'rehub_framework' ),
            'plugin_activated'                => __( 'Plugin activated successfully.', 'rehub_framework' ),
            'complete'                        => __( 'All plugins installed and activated successfully. %s', 'rehub_framework' ), // %s = dashboard link.
            'nag_type'                        => 'updated' // Determines admin notice type - can only be 'updated', 'update-nag' or 'error'.
        )
    );

    tgmpa( $plugins, $config );

}
}


/** Autocontents class
 * Taken from: wp-kama.ru/?p=1513
 * V: 2.9.4
 */
class Kama_Contents{    
	// defaults options
	public $opt = array(
		'margin'     => 40,
		'selectors'  => array('h2','h3','h4'),
		'to_menu'    => '↑',
		'title'      => '',
		'css'        => '',
		'min_found'  => 2,
		'min_length' => 1500,
		'page_url'   => '',
		'shortcode'  => 'contents',
		'spec'       => '\'.+$*~=',
		'wrap'       => '',
		'tag_inside' => '',
		// Какой тип анкора использовать: 'a' - <a name="anchor"></a> или 'id' - 
		'anchor_type' => 'a',
	);

	public $contents; // collect html contents

	private $temp;

	static $inst;

	function __construct( $args = array() ){
		$this->set_opt( $args );
		return $this;
	}

	static function init( $args = array() ){
		is_null( self::$inst ) && self::$inst = new self( $args );
		//if( $args ) self::$inst->set_opt( $args ); // ! NO
		return self::$inst;
	}

	function set_opt( $args = array() ){
		$this->opt = (object) array_merge( $this->opt, (array) $args );
	}

	function shortcode( $content, $contents_cb = '' ){
		if( false === strpos( $content, '['. $this->opt->shortcode ) ) 
			return $content; 

		// get contents data
		if( ! preg_match('~^(.*)\['. $this->opt->shortcode .'([^\]]*)\](.*)$~s', $content, $m ) )
			return $content;

		$contents = $this->make_contents( $m[3], $m[2] );

		if( $contents && $contents_cb && is_callable($contents_cb) )
			$contents = $contents_cb( $contents );

		return $m[1] . $contents . $m[3];
	}

	function make_contents( & $content, $tags = '' ){

		if( mb_strlen( strip_tags($content) ) < $this->opt->min_length ) return;

		$this->temp     = $this->opt;
		$this->temp->i  = 0;
		$this->contents = '';

		if( is_string($tags) && $tags = trim($tags) )
			$tags = array_map('trim', preg_split('~\s+~', $tags ) );

		if( ! $tags )
			$tags = $this->opt->selectors;

		// check tags
		foreach( $tags as $k => $tag ){
			// remove special marker tags and set $args
			if( in_array( $tag, array('embed','no_to_menu') ) ){
				if( $tag == 'embed' ) $this->temp->embed = true;
				if( $tag == 'no_to_menu' ) $this->opt->to_menu = false;

				unset( $tags[ $k ] );
				continue;
			}

			// remove tag if it's not exists in content
			$patt = ( ($tag[0] == '.') ? 'class=[\'"][^\'"]*'. substr($tag, 1) : "<$tag" );
			if( ! preg_match("/$patt/i", $content ) ){
				unset( $tags[ $k ] );
				continue;
			}
		}

		if( ! $tags ) return;

		// set patterns from given $tags
		// separate classes & tags & set
		$class_patt = $tag_patt = $level_tags = array();
		foreach( $tags as $tag ){
			// class
			if( $tag{0} == '.' ){
				$tag  = substr( $tag, 1 );
				$link = & $class_patt;
			}
			// html tag
			else
				$link = & $tag_patt;

			$link[] = $tag;         
			$level_tags[] = $tag;
		}

		$this->temp->level_tags = array_flip( $level_tags );

		$patt_in = array();
		if( $tag_patt )   $patt_in[] = '(?:<('. implode('|', $tag_patt) .')([^>]*)>(.*?)<\/\1>)';
		if( $class_patt ) $patt_in[] = '(?:<([^ >]+) ([^>]*class=["\'][^>]*('. implode('|', $class_patt) .')[^>]*["\'][^>]*)>(.*?)<\/'. ($patt_in?'\4':'\1') .'>)';

		$patt_in = implode('|', $patt_in );

		// collect and replace
		$_content = preg_replace_callback("/$patt_in/is", array( &$this, '__make_contents_callback'), $content, -1, $count );

		if( ! $count || $count < $this->opt->min_found )
			return;

		$content = $_content; // опять работаем с важной $content
		// html
		static $css;
		$embed = !! isset($this->temp->embed);
		$this->contents = 
			( ( $this->opt->wrap ) ? '<div id="'.$this->opt->wrap.'">' : '' ) .
			( ( !$embed && $this->opt->title ) ? '<div class="kc__wrap">' : '' ) .
			( ( ! $css && $this->opt->css )    ? '<style>'. $this->opt->css .'</style>' : '' ) .
			( ( !$embed && $this->opt->title ) ? '<div class="kc-title kc__title" id="kcmenu">'. $this->opt->title .'</div>'. "\n" : '' ) .
				'<ul class="autocontents"'. ((!$this->opt->title || $embed) ? ' id="kcmenu"' : '') .'>'. "\n". 
					implode('', $this->contents ) .
				'</ul>'."\n" .
			( ( !$embed && $this->opt->title ) ? '</div>' : '' ).
			( ( $this->opt->wrap ) ? '</div>' : '' );

		return $this->contents;
	}

	private function __make_contents_callback( $match ){
		// it's only class selector in pattern
		if( count($match) == 5 ){
			$tag   = $match[1];
			$attrs = $match[2];
			$title = $match[4];

			$level_tag = $match[3]; // class_name
		}
		// it's found tag selector
		elseif( count($match) == 4 ){
			$tag   = $match[1];
			$attrs = $match[2];
			$title = $match[3];

			$level_tag = $tag;
		}
		// it's found class selector
		else{
			$tag   = $match[4];
			$attrs = $match[5];
			$title = $match[7];

			$level_tag = $match[6]; // class_name
		}

		$anchor = $this->__sanitaze_anchor( $title );
		$opt = & $this->opt;

		$level = @ $this->temp->level_tags[ $level_tag ];
		if( $level > 0 )
			$sub = ( $opt->margin ? ' style="margin-left:'. ($level*$opt->margin) .'px;"' : '') . ' class="sub sub_'. $level .'"';
		else 
			$sub = ' class="top"';

		// собираем оглавление
		$this->contents[] = "\t". '<li'. $sub .'><a href="'. $opt->page_url .'#'. $anchor .'">'. $title .'</a></li>'. "\n";

		// заменяем
		$to_menu = $new_el = '';
		if( $opt->to_menu )
			$to_menu = (++$this->temp->i == 1) ? '' : '<a class="kc-gotop kc__gotop" href="'. $opt->page_url .'#kcmenu">'. $opt->to_menu .'</a>';

		$tag_inside_head = ( $opt->tag_inside) ? ' class="'.$opt->tag_inside.'"' : '';
		$new_el = "\n<$tag id=\"$anchor\" $tag_inside_head $attrs>$title</$tag>";
		if( $opt->anchor_type == 'a' )
			$new_el = '<a class="kc-anchor kc__anchor" name="'. $anchor .'"></a>'."\n<$tag $attrs>$title</$tag>";

		return $to_menu . $new_el;
	}

	## Транслитерация УРЛ
	private function __sanitaze_anchor( $str ){
		$str = strip_tags( $str );

		$iso9 = array(
			'А'=>'A', 'Б'=>'B', 'В'=>'V', 'Г'=>'G', 'Д'=>'D', 'Е'=>'E', 'Ё'=>'YO', 'Ж'=>'ZH',
			'З'=>'Z', 'И'=>'I', 'Й'=>'J', 'К'=>'K', 'Л'=>'L', 'М'=>'M', 'Н'=>'N', 'О'=>'O',
			'П'=>'P', 'Р'=>'R', 'С'=>'S', 'Т'=>'T', 'У'=>'U', 'Ф'=>'F', 'Х'=>'H', 'Ц'=>'TS',
			'Ч'=>'CH', 'Ш'=>'SH', 'Щ'=>'SHH', 'Ъ'=>'', 'Ы'=>'Y', 'Ь'=>'', 'Э'=>'E', 'Ю'=>'YU', 'Я'=>'YA',
			// small
			'а'=>'a', 'б'=>'b', 'в'=>'v', 'г'=>'g', 'д'=>'d', 'е'=>'e', 'ё'=>'yo', 'ж'=>'zh',
			'з'=>'z', 'и'=>'i', 'й'=>'j', 'к'=>'k', 'л'=>'l', 'м'=>'m', 'н'=>'n', 'о'=>'o',
			'п'=>'p', 'р'=>'r', 'с'=>'s', 'т'=>'t', 'у'=>'u', 'ф'=>'f', 'х'=>'h', 'ц'=>'ts',
			'ч'=>'ch', 'ш'=>'sh', 'щ'=>'shh', 'ъ'=>'', 'ы'=>'y', 'ь'=>'', 'э'=>'e', 'ю'=>'yu', 'я'=>'ya',
			// other
			'Ѓ'=>'G', 'Ґ'=>'G', 'Є'=>'YE', 'Ѕ'=>'Z', 'Ј'=>'J', 'І'=>'I', 'Ї'=>'YI', 'Ќ'=>'K', 'Љ'=>'L', 'Њ'=>'N', 'Ў'=>'U', 'Џ'=>'DH',          
			'ѓ'=>'g', 'ґ'=>'g', 'є'=>'ye', 'ѕ'=>'z', 'ј'=>'j', 'і'=>'i', 'ї'=>'yi', 'ќ'=>'k', 'љ'=>'l', 'њ'=>'n', 'ў'=>'u', 'џ'=>'dh'
		);

		$str = strtr( $str, $iso9 );

		$spec = preg_quote( $this->opt->spec );
		$str  = preg_replace("/[^a-zA-Z0-9\-_$spec]+/", '-', $str ); // все ненужное на '-'
		$str  = preg_replace('/^-+|-+$/', '', $str ); // кил конечные ---

		return strtolower( $str );
	}

	## Strip shortcode
	function strip_shortcode( $text ){
		return preg_replace('~\['. $this->opt->shortcode .'[^\]]*\]~', '', $text );
	}
}


## Proccesing contents shortcode
add_filter('the_content', 'rehub_contents_shortcode');
function rehub_contents_shortcode( $content ){
	$args = array();
	$args['to_menu']  = __('back to menu', 'rehub_framework').' ↑';

	$autocontents = new Kama_Contents($args);	
	if( is_singular() ){		
		return $autocontents->shortcode( $content );
	}
	else{
		return $autocontents->strip_shortcode( $content );
	}
}

## Proccesing toplist shortcode
add_filter('the_content', 'rehubtop_contents_shortcode');
function rehubtop_contents_shortcode( $content ){
	$args = array();
	$args['shortcode'] = 'wpsm_toplist';
	$args['anchor_type'] = 'id';
	$args['wrap'] = 'toplistmenu';
	$args['tag_inside'] = 'wpsm_toplist_heading';
	$args['to_menu']  = __('back to menu', 'rehub_framework').' ↑';	
	$args['selectors'] = array ('h2');
	$toplist = new Kama_Contents($args);

	if( is_singular() ){
		return $toplist->shortcode( $content );
	}
	else{
		return $toplist->strip_shortcode( $content );
	}
}

//remove some unuseful filter
remove_filter('comments_number', 'dsq_comments_text');
remove_filter('get_comments_number', 'dsq_comments_number');
remove_filter('pre_term_description', 'wp_filter_kses');
add_filter('widget_text', 'do_shortcode');
add_filter( 'category_description', 'do_shortcode' );

// Open Graph
function re_add_opengraph() {
	global $post;
	echo "<meta property='og:site_name' content='". get_bloginfo('name') ."'/>"; // Sets the site name to the one in your WordPress settings
	echo "<meta property='og:url' content='" . get_permalink() . "'/>"; // Gets the permalink to the post/page

	if (is_singular()) { // If we are on a blog post/page
        echo "<meta property='og:title' content='" . get_the_title() . "'/>"; // Gets the page title
        echo "<meta property='og:type' content='article'/>"; // Sets the content type to be article.
    } elseif(is_front_page() or is_home()) { // If it is the front page or home page
    	echo "<meta property='og:title' content='" . get_bloginfo("name") . "'/>"; // Get the site title
    	echo "<meta property='og:type' content='website'/>"; // Sets the content type to be website.
    }

	if(has_post_thumbnail( get_the_ID() )) { // If the post has a featured image.
		$thumbnail = wp_get_attachment_image_src( get_post_thumbnail_id( $post->ID ), 'large' );
		echo "<meta property='og:image' content='" . esc_attr( $thumbnail[0] ) . "'/>"; // If it has a featured image, then display this for Facebook
	} 
}
$using_jetpack_publicize = ( class_exists( 'Jetpack' ) && in_array( 'publicize', Jetpack::get_active_modules()) ) ? true : false;
if ( !defined('WPSEO_VERSION') && !class_exists('NY_OG_Admin') && $using_jetpack_publicize == false) {
	add_action( 'wp_head', 're_add_opengraph', 5 );
}

//VC init
if (class_exists('WPBakeryVisualComposerAbstract')) {
	if (defined('WPB_VC_VERSION') && version_compare(WPB_VC_VERSION, '4.6.0', '<')) {
		function my_admin_error_notice() {
			$class = "error";
			$message = __('Please, update your Visual composer to version > 4.6 You can deinstall VC and install again last version from notice at top of page. Or, use file js_composer.zip inside folder - theme_folder/plugins', 'rehub_framework');
		        echo"<div class=\"$class\"> <p>$message</p></div>"; 
		}
		add_action( 'admin_notices', 'my_admin_error_notice' );			
	}	

	if(!function_exists('add_rehub_to_vc')) {
		function add_rehub_to_vc(){
			require_once ( locate_template( 'functions/vc_functions.php' ) );
		}
	}
	if(!function_exists('rehub_vc_styles')) {
		function rehub_vc_styles() {
			wp_enqueue_style('rehub_vc', get_template_directory_uri() .'/functions/vc/vc.css', array(), time(), 'all');
		}
	}
	add_action('init','add_rehub_to_vc', 5);
	add_action('admin_enqueue_scripts', 'rehub_vc_styles');
	if(function_exists('thirstyInit')) { 
		remove_action('init', 'thirstyInit');	
	    add_action('init', 'thirstyInit', 4);
	}    
}

//Get site favicon
if (!function_exists('rehub_get_site_favicon')) {

    function rehub_get_site_favicon($url) {
        $shop = parse_url($url, PHP_URL_HOST);
        $shop = preg_replace('/^www\./', '', $shop);
        $shop_str = '<img src="//www.google.com/s2/favicons?domain=http://' . $shop . '"> ';
        $shop_str .= $shop;
        return $shop_str;
    }
} 

//Get social buttons
if( !function_exists('rehub_social_inimage') ) {
function rehub_social_inimage($small = '')
{	$small_class = ($small == 'minimal') ? ' small_social_inimage' : '';
	$output ='';
	$output .='<div class="social_icon social_icon_inimage'.$small_class.'">';
	$output .='<a href="https://www.facebook.com/sharer/sharer.php?u='.urlencode(get_permalink()).'" class="fb share-link-image" data-service="facebook"><i class="fa fa-facebook"></i></a>';
	$output .='<a href="https://twitter.com/share?url='.urlencode(get_permalink()).'" class="tw share-link-image" data-service="twitter"><i class="fa fa-twitter"></i></a>';
	$output .='<a href="https://pinterest.com/pin/create/button/?url='.urlencode(get_permalink()).'&amp;media='.get_post_thumb().'&amp;description='.urlencode(get_the_title()).'" class="pn share-link-image" data-service="pinterest"><i class="fa fa-pinterest-p"></i></a>';
	$output .='</div>';			
	return $output;	
}
}

//Search popup
function rehub_search_popup_block_footer(){
	?>
	<?php if(rehub_option('rehub_search_icon') == 'top' || rehub_option('rehub_search_icon') == 'menu') : ?>
	    <div id="search-header-contents-wraper">    
	        <div class="search-header-contents">
	        	<div class="re_title_inmodal"><?php _e('Search', 'rehub_framework'); ?></div>
	            <?php get_search_form(); ?>
	        </div>
	    </div>
	<?php endif ;?>
	<?php
}
add_action('wp_footer', 'rehub_search_popup_block_footer');

// Login / Register Modal
if (rehub_option('userlogin_enable') == '1') {
require_once ( locate_template( 'inc/user-login.php' ) );
}

// Compare functions
if (rehub_option('compare_page') != '') {
require_once ( locate_template( 'inc/compare.php' ) );
}

//////////////////////////////////////////////////////////////////
// Customization for UM
//////////////////////////////////////////////////////////////////

/* add new tab called "postoverview" */
add_filter('um_account_page_default_tabs_hook', 'rehub_tab_in_um', 100 );
if (!function_exists('rehub_tab_in_um')){
function rehub_tab_in_um( $tabs ) {
	$tabs[50]['postoverview']['icon'] = 'um-faicon-pencil';
	$tabs[50]['postoverview']['title'] = __('Overview', 'rehub_framework');
	$tabs[50]['postoverview']['custom'] = true;
	return $tabs;
}
}
	
/* make our new tab hookable */
add_action('um_account_tab__postoverview', 'um_account_tab__postoverview');
function um_account_tab__postoverview( $info ) {
	global $ultimatemember;
	extract( $info );
	$output = $ultimatemember->account->get_tab_output('postoverview');
	if ( $output ) { echo $output; }
}

/* Finally we add some content in the tab */
add_filter('um_account_content_hook_postoverview', 'um_account_content_hook_postoverview');
if (!function_exists('um_account_content_hook_postoverview')){
function um_account_content_hook_postoverview( $output ){
	$output = '<div class="um-field">';
		global $ultimatemember;
		$count_published = count_user_posts( um_profile_id());
		if ($count_published > 0) {
			$output .= '<span class="font120"><strong>';
			$output .= __('Your number of published posts: ', 'rehub_framework');
			$output .= '</strong>';
			$output .= $count_published;
			$output .= '</span>';
		}
		else {
			$output .= '<span class="font120"><strong>';
			$output .= __('You don\'t have published posts.', 'rehub_framework');
			$output .= '</strong>';
			$output .= '</span>';			
		}
		$sumbit_url = rehub_option('userlogin_submit_page');
		if ($sumbit_url) :
			$output .= '<a href="'. esc_url(get_the_permalink($sumbit_url)) .'" target="_blank" class="wpsm-button green medium floatright disablefloatmobile mt20"><i class="fa fa-cloud-upload"></i>'. __("Submit a Post", "rehub_framework") .'</a>';
		endif;
		$post_pending = new WP_Query( array( 'author' => um_profile_id(), 'posts_per_page' => -1, 'post_type' => 'any', 'nopaging' => true, 'post_status' => array( 'pending', 'draft', 'future' ) ) );
		if ( $post_pending->have_posts() ) {
			$output .= '<h3 class="mt20 mb5">'.__('Your last pending posts:', 'rehub_framework').'</h3>';
			while ( $post_pending->have_posts() ) {
				$post_pending->the_post();
				$output .= '<div class="um-item"><div class="um-item-link"><i class="um-icon-ios-paper"></i><a href="'.get_the_permalink().'">'.get_the_title().'</a></div></div>';
			}
		}
		else {
			$output .= '<p><strong>';
			$output .= __('You don\'t have pending posts. ', 'rehub_framework');
			$output .= '</strong></p>';
		}
		wp_reset_postdata();
		
	$output .= '</div>';		

	return $output;
}
}

/* Add wpsocial login buttons to UM */
add_action('um_before_login_fields', 'um_rehub_show_social_inform');
add_action('um_before_register_fields', 'um_rehub_show_social_inform');
if (!function_exists('um_rehub_show_social_inform')) {
	function um_rehub_show_social_inform($args){
		$args = do_action( 'wordpress_social_login' );
		echo $args;
	}
}

/* Add FontAwesome icons to WP social login */
if( !function_exists('wslrehub_use_fontawesome_icons') ) {
function wslrehub_use_fontawesome_icons( $provider_id, $provider_name, $authenticate_url ){ ?>
   <a rel="nofollow" href="<?php echo $authenticate_url; ?>" data-provider="<?php echo $provider_id ?>" class="wp-social-login-provider wp-social-login-provider-<?php echo strtolower( $provider_id ); ?>">
      <span>
         <i class="fa fa-<?php echo strtolower( $provider_id ); ?>"></i>
         <?php echo $provider_name; ?>
      </span>
   </a><?php
}
add_filter( 'wsl_render_auth_widget_alter_provider_icon_markup', 'wslrehub_use_fontawesome_icons', 10, 3 );	
}

/* Remove admin bar from users */
if( !function_exists('re_remove_admin_bar') ) {
function re_remove_admin_bar() {
	if(!current_user_can('administrator') && !is_admin() && rehub_option('remove_admin_bar') =='1'){
		show_admin_bar(false);
	}
}
add_action('after_setup_theme', 're_remove_admin_bar');
}


if(!function_exists('rehub_get_ip')) {
	#get the user's ip address
	function rehub_get_ip() {
		if (empty($_SERVER["HTTP_X_FORWARDED_FOR"])) {
			$ip_address = $_SERVER["REMOTE_ADDR"];
		} else {
			$ip_address = $_SERVER["HTTP_X_FORWARDED_FOR"];
		}
		if(strpos($ip_address, ',') !== false) {
			$ip_address = explode(',', $ip_address);
			$ip_address = $ip_address[0];
		}
		return esc_attr($ip_address);
	}
}

if (!function_exists('rehub_truncate_title')) {
	#get custom length titles
	function rehub_truncate_title($len = 110, $id = NULL) {
		$title = get_the_title($id);		
		if (!empty($len) && mb_strlen($title)>$len) $title = mb_substr($title, 0, $len-3) . "...";
		return $title;
	}
}

/* Pagination fix for custom loops on pages */
add_filter('redirect_canonical','rehub_disable_redirect_canonical');
function rehub_disable_redirect_canonical($redirect_url) {if (is_paged() && is_singular()) $redirect_url = false; return $redirect_url; }

?>