<?php
//////////////////////////////////////////////////////////////////
// WooCommerce
//////////////////////////////////////////////////////////////////
if (class_exists('Woocommerce')) {
	if ( version_compare( WOOCOMMERCE_VERSION, "2.1" ) >= 0 ) {
	   add_filter( 'woocommerce_enqueue_styles', '__return_false' );
	} else {
	   define( 'WOOCOMMERCE_USE_CSS', false );
	}
}
// Display number products per page.
if(rehub_option('woo_number') == '16') {
	add_filter( 'loop_shop_per_page', create_function( '$cols', 'return 16;' ), 20 );
}
else {
	add_filter( 'loop_shop_per_page', create_function( '$cols', 'return 12;' ), 20 );	
}

add_action('woocommerce_before_shop_loop', 'rehub_woocommerce_wrapper_start3', 33);
function rehub_woocommerce_wrapper_start3() {
  echo '<div class="clear"></div>';
}


global $pagenow;
if ( is_admin() && isset( $_GET['activated'] ) && $pagenow == 'themes.php' )
	add_action( 'init', 'rehub_woocommerce_image_dimensions', 1 );

if( !function_exists('rehub_woocommerce_image_dimensions') ) {
function rehub_woocommerce_image_dimensions() {
  	$catalog = array(
		'width' 	=> '400',	// px
		'height'	=> '400',	// px
		'crop'		=> 1 		// true
	);
 
	$single = array(
		'width' 	=> '600',	// px
		'height'	=> '600',	// px
		'crop'		=> 1 		// true
	);
 
	$thumbnail = array(
		'width' 	=> '200',	// px
		'height'	=> '200',	// px
		'crop'		=> 1 		// false
	);
 
	// Image sizes
	update_option( 'shop_catalog_image_size', $catalog ); 		// Product category thumbs
	update_option( 'shop_single_image_size', $single ); 		// Single product image
	update_option( 'shop_thumbnail_image_size', $thumbnail ); 	// Image gallery thumbs
}
}

// Ensure cart contents update when products are added to the cart via AJAX (place the following in functions.php)
add_filter('add_to_cart_fragments', 'woocommerce_header_add_to_cart_fragment');

if( !function_exists('woocommerce_header_add_to_cart_fragment') ) { 
function woocommerce_header_add_to_cart_fragment( $fragments ) {
	global $woocommerce;
	ob_start();
	?>
		<a class="cart-contents cart_count_<?php echo $woocommerce->cart->cart_contents_count; ?>" href="<?php echo $woocommerce->cart->get_cart_url(); ?>"><i class="fa fa-shopping-cart"></i> <?php _e( 'Cart', 'rehub_framework' ); ?> (<?php echo $woocommerce->cart->cart_contents_count; ?>) - <?php echo $woocommerce->cart->get_cart_total(); ?></a>
	<?php
	$fragments['a.cart-contents'] = ob_get_clean();
	return $fragments;
}
}

/* Redirect Vendors to Vendor Dashboard on Login */
add_filter('woocommerce_login_redirect', 'login_redirect', 10, 2);
function login_redirect( $redirect_to, $user ) {
    
    if (class_exists('WCV_Vendors') && class_exists('WCVendors_Pro') && WCV_Vendors::is_vendor( $user->id ) ) {
        $redirect_to = get_permalink(WCVendors_Pro::get_option( 'dashboard_page_id' ));
    }
    elseif (class_exists('WCV_Vendors') && WCV_Vendors::is_vendor( $user->id ) ) {
    	$redirect_to = get_permalink(WC_Vendors::$pv_options->get_option( 'vendor_dashboard_page' ));
    }
    return $redirect_to;
}

if( !function_exists('woo_dealslinks_rehub') ) {
function woo_dealslinks_rehub() {
?>
	<?php if (vp_metabox('rehub_framework_woo.rehub_deals_title')) :?>
		<?php $deal_title = vp_metabox('rehub_framework_woo.rehub_deals_title');?>
	<?php elseif (rehub_option('rehub_choosedeal_text') !=''):?>
		<?php $deal_title = rehub_option('rehub_choosedeal_text');?>
	<?php else :?>
		<?php $deal_title = __('Choose your deal', 'rehub_framework');?>
	<?php endif;?>
	<?php $rehub_woo_post_ids = vp_metabox('rehub_framework_woo.review_woo_list_links'); 
	if (!empty($rehub_woo_post_ids) && !is_array($rehub_woo_post_ids)) { $rehub_woo_post_ids = explode(',', $rehub_woo_post_ids); }
	$rehub_aff_post_ids = vp_metabox('rehub_framework_woo.review_woo_links');
	$rehub_woodeals_short = vp_metabox('rehub_framework_woo.rehub_woodeals_short');
	?>
    <?php if (!empty ($rehub_woodeals_short)) :?>
    	<div class="deals_woo_short">
    		<?php echo do_shortcode($rehub_woodeals_short);?>
    	</div>
    <?php endif;?>	
	<?php if(!empty($rehub_woo_post_ids) || (function_exists('thirstyInit') && !empty($rehub_aff_post_ids))) :?>
		<div class="deals_woo_rehub">
			<div class="title_deal_wrap"><div class="title_deal"><?php echo esc_html($deal_title); ?></div></div>
			<?php if(!empty($rehub_woo_post_ids)) :?>
				<div class="wooaff_offer_links">
				<?php  $args = array(
		            'post__in' => $rehub_woo_post_ids,
		            'numberposts' => '-1',
		            'orderby' => 'post__in', 
		            'post_type' => 'product',
		            'ignore_sticky_posts'   => 1,
		            'no_found_rows' => 1,           
		        ); 
		        global $post; global $woocommerce; $backup=$post;
		        ?>
		        <?php $i=1; $wp_query = new WP_Query( $args ); if ( $wp_query->have_posts() ) : ?>                      
				<?php while ( $wp_query->have_posts() ) : $wp_query->the_post();  global $product;  ?>
				<?php $woolink = ($product->product_type =='external') ? $product->add_to_cart_url() : get_post_permalink(get_the_ID()) ;?>
				<?php $term_ids =  wp_get_post_terms(get_the_ID(), 'product_tag', array("fields" => "ids")); if (!empty($term_ids)) {$term_brand = $term_ids[0]; $term_brand_image = get_option("taxonomy_term_$term_ids[0]");} else {$term_brand_image ='';}
				$woo_img = get_post_thumb();
				?>   
					<div class="woorow_aff">
						<div class="product-pic-wrapper">
							<a href="<?php echo $woolink; ?>" target="_blank"<?php if ($product->product_type =='external'){echo ' rel="nofollow"';} ?>>
								<?php if (!empty($woo_img) ) :?>	
			            			<img src="<?php $params = array( 'width' => 100, 'height' => 100 ); echo bfi_thumb( $woo_img, $params ); ?>" alt="<?php the_title_attribute(); ?>" />
			            		<?php elseif (!empty($term_brand_image['brand_image'])) :?>
			            			<img src="<?php $params = array( 'width' => 100, 'height' => 100 ); echo bfi_thumb( $term_brand_image['brand_image'], $params ); ?>" alt="<?php the_title_attribute(); ?>" />
			            		<?php else :?>
			            			<img src="<?php echo get_template_directory_uri(); ?>/images/default/noimage_100_70.png" alt="<?php the_title_attribute(); ?>" />
			            		<?php endif?>
			            	</a>				
						</div>
						<div class="product-details">
							<div class="product-name">
								<div class="aff_name"><a href="<?php echo $woolink; ?>" target="_blank"<?php if ($product->product_type =='external'){echo ' rel="nofollow"';} ?>><?php the_title(); ?></a></div>
								<p><?php kama_excerpt('maxchar=150'); ?></p>
							</div>
							<div class="left_data_aff">
								<div class="wooprice_count">
								<?php if ($product->get_price() !='') : ?>
									<?php echo $product->get_price_html(); ?>
								<?php endif; ?>	
								</div>					
								<div class="wooaff_tag">
						            <?php if (!empty($term_brand_image['brand_image'])) :?>
						            	<img src="<?php $params = array( 'width' => 100, 'height' => 100 ); echo bfi_thumb( $term_brand_image['brand_image'], $params ); ?>" alt="<?php the_title_attribute(); ?>" />
						            <?php elseif (!empty($term_list[0])) :?> 
						            	<?php echo $term_list[0]; ?>
						            <?php endif; ?> 							
								</div>
							</div>					
							<div class="woobuy_butt">
		                    <?php if ( $product->is_in_stock() &&  $product->add_to_cart_url() !='') : ?>
		                        <?php  echo apply_filters( 'woocommerce_loop_add_to_cart_link',
		                            sprintf( '<a href="%s" data-product_id="%s" data-product_sku="%s" class="woobtn_offer_block %s product_type_%s"%s%s>%s</a>',
		                            esc_url( $product->add_to_cart_url() ),
		                            esc_attr( $product->id ),
		                            esc_attr( $product->get_sku() ),
		                            $product->is_purchasable() && $product->is_in_stock() ? 'add_to_cart_button' : 'add_to_cart_button',
		                            esc_attr( $product->product_type ),
		                            $product->product_type =='external' ? ' target="_blank"' : '',
		                            $product->product_type =='external' ? ' rel="nofollow"' : '',                            
		                            $product->add_to_cart_text() ? esc_html( $product->add_to_cart_text()) : __('See it', 'rehub_framework')
		                            ),
		                        $product );?>
		                    <?php endif; ?>
							</div>
						</div>
					</div>
					<?php endwhile; endif; wp_reset_postdata(); $post=$backup; ?> 
				</div>
			<?php endif ;?>
			<?php if(function_exists('thirstyInit') && !empty($rehub_aff_post_ids)) :?>		
				<div class="wooaff_offer_links">
				<?php 
				$rehub_aff_posts = get_posts(array(
					'post_type'        => 'thirstylink',
					'post__in' => $rehub_aff_post_ids,
					'meta_key' => 'rehub_aff_sticky',
					'orderby' => 'meta_value',
					'order' => 'DESC',
					'numberposts' => '-1'			
				));
				foreach($rehub_aff_posts as $aff_post) { ?>	
					<?php 	$attachments = get_posts( array(
			            'post_type' => 'attachment',
						'post_mime_type' => 'image',
			            'posts_per_page' => -1,
			            'post_parent' => $aff_post->ID,
		        	) );
					if (!empty($attachments)) {$aff_thumb_list = wp_get_attachment_url( $attachments[0]->ID );} else {$aff_thumb_list ='';}
					$term_list = wp_get_post_terms($aff_post->ID, 'thirstylink-category', array("fields" => "names")); 
					$term_ids =  wp_get_post_terms($aff_post->ID, 'thirstylink-category', array("fields" => "ids")); if (!empty($term_ids)) {$term_brand = $term_ids[0]; $term_brand_image = get_option("taxonomy_term_$term_ids[0]");} else {$term_brand_image ='';}
					?>
					<div class="woorow_aff">
						<div class="product-pic-wrapper">
							<a href="<?php echo get_post_permalink($aff_post) ?>">
								<?php if (!empty($aff_thumb_list) ) :?>	
			            			<img src="<?php $params = array( 'width' => 100, 'height' => 100 ); echo bfi_thumb( $aff_thumb_list, $params ); ?>" alt="<?php echo $aff_post->post_title; ?>" />
			            		<?php elseif (!empty($term_brand_image['brand_image'])) :?>
			            			<img src="<?php $params = array( 'width' => 100, 'height' => 100 ); echo bfi_thumb( $term_brand_image['brand_image'], $params ); ?>" alt="<?php echo $aff_post->post_title; ?>" />
			            		<?php else :?>
			            			<img src="<?php echo get_template_directory_uri(); ?>/images/default/noimage_100_70.png" alt="<?php echo $aff_post->post_title; ?>" />
			            		<?php endif?>
			            	</a>				
						</div>
						<div class="product-details">
							<div class="product-name">
								<div class="aff_name"><a href="<?php echo get_post_permalink($aff_post) ?>"><?php echo $aff_post->post_title; ?></a></div>
								<p><?php echo get_post_meta( $aff_post->ID, 'rehub_aff_desc', true );?></p>
							</div>
							<div class="left_data_aff">
								<div class="wooprice_count">
									<?php $product_price = get_post_meta( $aff_post->ID, 'rehub_aff_price', true );?>
									<?php echo $product_price ;?>
								</div>					
								<div class="wooaff_tag">
						            <?php if (!empty($term_brand_image['brand_image'])) :?>
						            	<img src="<?php $params = array( 'width' => 100, 'height' => 100 ); echo bfi_thumb( $term_brand_image['brand_image'], $params ); ?>" alt="<?php the_title_attribute(); ?>" />
						            <?php elseif (!empty($term_list[0])) :?> 
						            	<?php echo $term_list[0]; ?>
						            <?php endif; ?> 							
								</div>
							</div>	
							<?php $offer_btn_text = get_post_meta( $aff_post->ID, 'rehub_aff_btn_text', true ) ?>				
							<div class="woobuy_butt">
								<a class="woobtn_offer_block" href="<?php echo get_post_permalink($aff_post) ?>" target="_blank" rel="nofollow"><?php if($offer_btn_text !='') :?><?php echo $offer_btn_text ; ?><?php elseif(rehub_option('rehub_btn_text') !='') :?><?php echo rehub_option('rehub_btn_text') ; ?><?php else :?><?php _e('See it', 'rehub_framework') ?><?php endif ;?></a>
							</div>
						</div>
					</div>	
				<?php 
				}
				?>
				</div>
			<?php endif;?>
		</div>
    <?php endif;?>	
<?php
}
}
          
add_action( 'woocommerce_after_single_product_summary', 'woo_dealslinks_rehub', 9 ); //add affiliate links to woocommerce

// Add the Meta Box to woocommerce for using coupons
function add_rehub_woo_meta_box() {
    add_meta_box(
        'woo_rehub_coupons', // $id
        'Coupons for Affiliate', // $title 
        'show_rehub_woo_meta_box', // $callback
        'product', // $page
        'normal', // $context
        'low'); // $priority
}
add_action('add_meta_boxes', 'add_rehub_woo_meta_box');

// Field Array
$wooprefixrehub = 'rehub_woo_coupon_';
$woo_custom_meta_fields = array(
    array(
        'label'=>  __('Set coupon code', 'rehub_framework'),
        'desc'  => __('Set coupon code or leave blank', 'rehub_framework'),
        'id'    => $wooprefixrehub.'code',
        'type'  => 'text'
    ),
	array(
	    'label' => __('Coupon End Date', 'rehub_framework'),
	    'desc'  => __('Choose expiration date of coupon or leave blank', 'rehub_framework'),
	    'id'    => $wooprefixrehub.'date',
	    'type'  => 'date'
	),    
    array(
        'label'=> __('Mask coupon code?', 'rehub_framework'),
        'desc'  => __('If this option is enabled, coupon code will be hidden.', 'rehub_framework'),
        'id'    => $wooprefixrehub.'mask',
        'type'  => 'checkbox'
    ),
    array(
        'label'=> __('Brand logo url', 'rehub_framework'),
        'desc'  => __('Insert url to logo of brand or leave blank', 'rehub_framework'),
        'id'    => $wooprefixrehub.'logo_url',
        'type'  => 'text'
    )        
);

// The Callback
function show_rehub_woo_meta_box() {
global $woo_custom_meta_fields, $post;
// Use nonce for verification
echo '<input type="hidden" name="custom_woo_meta_box_nonce" value="'.wp_create_nonce(basename(__FILE__)).'" />';
     
    // Begin the field table and loop
    echo '<table class="form-table">';
    foreach ($woo_custom_meta_fields as $field) {
        // get value of this field if it exists for this post
        $meta = get_post_meta($post->ID, $field['id'], true);
        // begin a table row with
        echo '<tr>
                <th><label for="'.$field['id'].'">'.$field['label'].'</label></th>
                <td>';
                switch($field['type']) {
                    // text
					case 'text':
					    echo '<input type="text" name="'.$field['id'].'" id="'.$field['id'].'" value="'.$meta.'" size="70" />
					        <br /><span class="description">'.$field['desc'].'</span>';
					break;
					// checkbox
					case 'checkbox':
					    echo '<input type="checkbox" name="'.$field['id'].'" id="'.$field['id'].'" ',$meta ? ' checked="checked"' : '','/>
					        <label for="'.$field['id'].'">'.$field['desc'].'</label>';
					break;
					// date
					case 'date':
						echo '<input type="text" class="rehubdatepicker" name="'.$field['id'].'" id="'.$field['id'].'" value="'.$meta.'" size="70" />
								<br /><span class="description">'.$field['desc'].'</span>';
					break;															
                } //end switch
        echo '</td></tr>';
    } // end foreach
    echo '</table>'; // end table
}

add_action('admin_head','rehub_add_woo_custom_scripts',11);
if ( !function_exists( 'rehub_add_woo_custom_scripts' ) ) {
function rehub_add_woo_custom_scripts() {
    global $woo_custom_meta_fields, $post, $pagenow;
    if ( $pagenow=='post-new.php' || $pagenow=='post.php' ) {
	    if ( 'product' === $post->post_type ) { 
		    $output = '<script type="text/javascript">
		                jQuery(function() {';	                 
		    foreach ($woo_custom_meta_fields as $field) { // loop through the fields looking for certain types
		        if($field['type'] == 'date')
		            $output .= 'jQuery(".rehubdatepicker").each(function(){jQuery(this).datepicker({dateFormat: "yy-mm-dd"});});';
		    };	     
		    $output .= '});
		        </script>';	         
		    echo $output;
		}
	}
}
}

// Save the Data
function save_rehub_woo_custom_meta($post_id) {
    global $woo_custom_meta_fields;
     
    // verify nonce
	if ( ! isset( $_POST['custom_woo_meta_box_nonce'] ) ) {
		return $post_id;
	}
    if (!wp_verify_nonce($_POST['custom_woo_meta_box_nonce'], basename(__FILE__))) 
        return $post_id;
    // check autosave
    if (defined('DOING_AUTOSAVE') && DOING_AUTOSAVE)
        return $post_id;
    // check permissions
    if ( isset( $_POST['post_type'] ) && 'page' == $_POST['post_type'] ) {
        if (!current_user_can('edit_page', $post_id))
            return $post_id;
        } elseif (!current_user_can('edit_post', $post_id)) {
            return $post_id;
    }
     
    // loop through fields and save the data
    foreach ($woo_custom_meta_fields as $field) {
        $old = get_post_meta($post_id, $field['id'], true);
        if (isset ($_POST[$field['id']])) {
            $new = sanitize_text_field($_POST[$field['id']]);
        }
        else {
           $new =''; 
        }
        if ($new && $new != $old) {
            update_post_meta($post_id, $field['id'], $new);
        } elseif ('' == $new && $old) {
            delete_post_meta($post_id, $field['id'], $old);
        }
    } // end foreach
}
add_action('save_post', 'save_rehub_woo_custom_meta');

if( !function_exists('woo_coupon_rehub') ) {
function woo_coupon_rehub() {
?>
<?php 
	$term_ids =  wp_get_post_terms(get_the_ID(), 'product_tag', array("fields" => "ids")); 
    $brand_url = get_post_meta( get_the_ID(), 'rehub_woo_coupon_logo_url', true );
    if (!empty ($brand_url)) {
        $term_brand_image = esc_url($brand_url);
    }   
    elseif (!empty($term_ids)) {
        $term_brand = $term_ids[0]; 
        $term_brand_id = get_option("taxonomy_term_$term_ids[0]"); 
        $term_brand_image = ($term_brand_id['brand_image']) ? $term_brand_id['brand_image'] : '';
    }
    else {
        $term_brand_image ='';
    }
?>        
<?php if (!empty($term_brand_image)) :?>   
    <div class="brand_logo_small"><img src="<?php $params = array( 'width' => 40); echo bfi_thumb( $term_brand_image, $params ); ?>" alt="<?php the_title_attribute(); ?>" /></div>
<?php endif; ?> 
<?php  global $product; $offer_coupon = get_post_meta( get_the_ID(), 'rehub_woo_coupon_code', true ) ?>
<?php $offer_coupon_date = get_post_meta( get_the_ID(), 'rehub_woo_coupon_date', true ) ?>
<?php $offer_coupon_mask = get_post_meta( get_the_ID(), 'rehub_woo_coupon_mask', true ) ?>
<?php $offer_url = $product->add_to_cart_url(); ?>
<?php $coupon_style = ''; if(!empty($offer_coupon_date)) : ?>
	<?php 
	$timestamp1 = strtotime($offer_coupon_date); 
	$seconds = $timestamp1 - time(); 
	$days = floor($seconds / 86400);
	$seconds %= 86400;
	if ($days > 0) {
	  $coupon_text = $days.' '.__('days left', 'rehub_framework');
	  $coupon_style = '';
	}
	elseif ($days == 0){
	  $coupon_text = __('Last day', 'rehub_framework');
	  $coupon_style = '';
	}
	else {
	  $coupon_text = __('Coupon is Expired', 'rehub_framework');
	  $coupon_style = 'expired_coupon';
	}                 
	?>
<?php endif ;?>
<?php $coupon_enabled_style = (!empty($offer_coupon_mask)) ? ' reveal_enabled '.$coupon_style.'' : ' '.$coupon_style.'' ?>
<div class="coupon_woo_rehub<?php echo $coupon_enabled_style ;?>">
  	<?php if(!empty($offer_coupon)) : ?>
		<?php wp_enqueue_script('zeroclipboard'); ?>
		<?php if ($offer_coupon_mask !='1' && $offer_coupon_mask !='on') :?>
		  <div class="rehub_offer_coupon not_masked_coupon <?php if(!empty($offer_coupon_date)) {echo $coupon_style ;} ?>" data-clipboard-text="<?php echo $offer_coupon ?>"><i class="fa fa-scissors fa-rotate-180"></i><span class="coupon_text"><?php echo $offer_coupon ?></span></div>   
		<?php else :?>
		  <div class="rehub_offer_coupon masked_coupon <?php if(!empty($offer_coupon_date)) {echo $coupon_style ;} ?>" data-clipboard-text="<?php echo $offer_coupon ?>" data-codeid="<?php echo $product->id ?>" data-dest="<?php echo $offer_url ?>"><?php if(rehub_option('rehub_mask_text') !='') :?><?php echo rehub_option('rehub_mask_text') ; ?><?php else :?><?php _e('Reveal coupon', 'rehub_framework') ?><?php endif ;?><i class="fa fa-external-link-square"></i></div>   
		<?php endif;?>
		<?php if(!empty($offer_coupon_date)) {echo '<div class="time_offer">'.$coupon_text.'</div>';} ?>    
  	<?php endif ;?> 
</div>
<?php
}
}
          
add_action( 'woocommerce_before_add_to_cart_button', 'woo_coupon_rehub', 9 ); //add affiliate links to woocommerce


if (rehub_option('woo_exclude_expired') == '1') {//exclude expired coupons frop loops

	//exclude from main archives
	if (!function_exists('woo_exclude_expired')) {
		function woo_exclude_expired($query) {
			if( ! is_admin() && $query->is_main_query() ) {
			    if (is_post_type_archive('product') || is_product_category()) {
				    $query->set( 'meta_query', array(
				    	'relation' => 'OR',
				    	array(
				       		'key' => 'rehub_woo_coupon_date',
				       		'value' => date('Y-m-d'),
				       		'compare' => '>=',
				    	),
				    	array(
				       		'key' => 'rehub_woo_coupon_date',
				       		'compare' => 'NOT EXISTS',
				    	),	    	
				    ));
				}
			}
		}
	add_action('pre_get_posts','woo_exclude_expired');		
	}

	//exclude from related products
	if (!function_exists('woo_exclude_expired_args')) {
	function woo_exclude_expired_args( $args ) {
	    $args['meta_query'] = array(
	    	'relation' => 'OR',
	    	array(
	       		'key' => 'rehub_woo_coupon_date',
	       		'value' => date('Y-m-d'),
	       		'compare' => '>=',
	    	),
	    	array(
	       		'key' => 'rehub_woo_coupon_date',
	       		'compare' => 'NOT EXISTS',
	    	),	    	
		);
		return $args;
	}
	add_filter( 'woocommerce_related_products_args', 'woo_exclude_expired_args' );
	}

}

?>