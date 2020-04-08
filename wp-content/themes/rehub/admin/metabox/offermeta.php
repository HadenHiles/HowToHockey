<?php

// enqueue scripts and styles, but only if is_admin
add_action( 'admin_enqueue_scripts', 'reh_date_picker_fallback' );
function reh_date_picker_fallback() {
    wp_enqueue_script('jquery-ui-datepicker');
}

// Add the Meta Box to post for using coupons
function add_rehub_post_meta_box() {
    add_meta_box(
        'post_rehub_offers', // $id
        'Post offer', // $title 
        'show_rehub_post_meta_box', // $callback
        'post', // $page
        'normal', // $context
        'low'); // $priority
}
add_action('add_meta_boxes', 'add_rehub_post_meta_box');

// Field Array
$postprefixrehub = 'rehub_offer_';
$post_custom_meta_fields = array(
    array(
        'label'=>  __('Offer url', 'rehub_framework'),
        'desc'  => __('Insert url of offer', 'rehub_framework'),
        'id'    => $postprefixrehub.'product_url',
        'type'  => 'text'
    ),	
    array(
        'label'=>  __('Name of product', 'rehub_framework'),
        'desc'  => __('Insert title or leave blank', 'rehub_framework'),
        'id'    => $postprefixrehub.'name',
        'type'  => 'text'
    ),
    array(
        'label'=>  __('Short description of product', 'rehub_framework'),
        'desc'  => __('Enter description of product or leave blank', 'rehub_framework'),
        'id'    => $postprefixrehub.'product_desc',
        'type'  => 'text'
    ), 
    array(
        'label'=>  __('Offer old price', 'rehub_framework'),
        'desc'  => __('Insert old price of offer or leave blank', 'rehub_framework'),
        'id'    => $postprefixrehub.'product_price_old',
        'type'  => 'text'
    ), 
    array(
        'label'=>  __('Offer sale price', 'rehub_framework'),
        'desc'  => __('Insert sale price of offer (example, $55). Please, choose your price pattern in theme options - localizations', 'rehub_framework'),
        'id'    => $postprefixrehub.'product_price',
        'type'  => 'text'
    ),  
    array(
        'label'=>  __('Set coupon code', 'rehub_framework'),
        'desc'  => __('Set coupon code or leave blank', 'rehub_framework'),
        'id'    => $postprefixrehub.'product_coupon',
        'type'  => 'text'
    ),            
	array(
	    'label' => __('Coupon End Date', 'rehub_framework'),
	    'desc'  => __('Choose expiration date of coupon or leave blank', 'rehub_framework'),
	    'id'    => $postprefixrehub.'coupon_date',
	    'type'  => 'date'
	),    
    array(
        'label'=> __('Mask coupon code?', 'rehub_framework'),
        'desc'  => __('If this option is enabled, coupon code will be hidden.', 'rehub_framework'),
        'id'    => $postprefixrehub.'coupon_mask',
        'type'  => 'checkbox'
    ),
    array(
        'label'=> __('Button text', 'rehub_framework'),
        'desc'  => __('Insert text on button or leave blank to use default text. Use short names (not more than 14 symbols)', 'rehub_framework'),
        'id'    => $postprefixrehub.'btn_text',
        'type'  => 'text'
    ),     
	array(
	    'label'  => __('Upload thumbnail', 'rehub_framework'),
	    'desc'  => __('Upload thumbnail of product or leave blank to use post thumbnail', 'rehub_framework'),
	    'id'    => $postprefixrehub.'product_thumb',
	    'type'  => 'image'
	),
    array(
        'label'=> __('Brand logo url', 'rehub_framework'),
        'desc'  => __('Insert url to logo of brand or leave blank', 'rehub_framework'),
        'id'    => $postprefixrehub.'logo_url',
        'type'  => 'text'
    ),    
    array(
        'label'=> __('Enable shortcode inserting', 'rehub_framework'),
        'desc'  => __('If enable you can insert offer box in any place of content with shortcode [quick_offer]. If disable - it will be before review box.', 'rehub_framework'),
        'id'    => $postprefixrehub.'shortcode',
        'type'  => 'checkbox'
    ),	    
);

// The Callback
function show_rehub_post_meta_box() {
global $post_custom_meta_fields, $post;
// Use nonce for verification
echo '<input type="hidden" name="custom_post_meta_box_nonce" value="'.wp_create_nonce(basename(__FILE__)).'" />';
     
    // Begin the field table and loop
    echo '<table class="form-table">';
    foreach ($post_custom_meta_fields as $field) {
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
					    echo '<input type="checkbox" name="'.$field['id'].'" value ="1" id="'.$field['id'].'" ',$meta ? ' checked="checked"' : '','/>
					        <label for="'.$field['id'].'">'.$field['desc'].'</label>';
					break;
					// date
					case 'date':
						echo '<input type="text" class="rehubdatepicker" name="'.$field['id'].'" id="'.$field['id'].'" value="'.$meta.'" size="70" />
								<br /><span class="description">'.$field['desc'].'</span>';
					break;	
					// image
					case 'image':
						$image = get_template_directory_uri().'/images/default/noimage_100_70.png';
						echo '<div class="meta_box_image"><span class="meta_box_default_image" style="display:none">' . $image . '</span>';
						if ( $meta ) {
							$image = $meta;
						}				
						echo	
							'<input name="' . esc_attr( $field['id'] ) . '" type="text" size="70" class="meta_box_upload_image" value="' . esc_url( $meta ) . '" />									
							<a href="#" class="meta_box_upload_image_button button" rel="' . get_the_ID() . '">'.__('Choose Image', 'rehub_framework').'</a>
							<small>&nbsp;<a href="#" class="meta_box_clear_image_button button">X</a></small>
							<br /><br />
							<img src="' . esc_attr( $image ) . '" class="meta_box_preview_image" alt="" style="max-width: 200px" /></div>
							<br clear="all" />' . $field['desc'];
					break;														
                } //end switch
        echo '</td></tr>';
    } // end foreach
    echo '</table>'; // end table
}


add_action('admin_head','rehub_add_post_custom_scripts',11);
if ( !function_exists( 'rehub_add_post_custom_scripts' ) ) {
function rehub_add_post_custom_scripts() {
    global $post_custom_meta_fields, $post, $pagenow;
    if ( $pagenow=='post-new.php' || $pagenow=='post.php' ) {
	    if ( 'post' === $post->post_type ) { 
		    $output = '<script type="text/javascript">
		                jQuery(function() {';	                 
		    foreach ($post_custom_meta_fields as $field) { // loop through the fields looking for certain types
		        if($field['type'] == 'date')
		            $output .= 'jQuery(".rehubdatepicker").each(function(){jQuery(this).datepicker({dateFormat: "yy-mm-dd"});});';
		        if($field['type'] == 'image')
		            $output .= 'var imageFrame;jQuery(".meta_box_upload_image_button").click(function(e){e.preventDefault();return $self=jQuery(e.target),$div=$self.closest("div.meta_box_image"),imageFrame?void imageFrame.open():(imageFrame=wp.media({title:"Choose Image",multiple:!1,library:{type:"image"},button:{text:"Use This Image"}}),imageFrame.on("select",function(){selection=imageFrame.state().get("selection"),selection&&selection.each(function(e){console.log(e);{var t=e.attributes.sizes.full.url;e.id}$div.find(".meta_box_preview_image").attr("src",t),$div.find(".meta_box_upload_image").val(t)})}),void imageFrame.open())}),jQuery(".meta_box_clear_image_button").click(function(){var e=jQuery(this).parent().siblings(".meta_box_default_image").text();return jQuery(this).parent().siblings(".meta_box_upload_image").val(""),jQuery(this).parent().siblings(".meta_box_preview_image").attr("src",e),!1});';        
		    };	     
		    $output .= '});
		        </script>';	         
		    echo $output;
		}
	}
}
}

// Save the Data
function save_rehub_post_custom_meta($post_id) {
    global $post_custom_meta_fields;
     
    // verify nonce
	if ( ! isset( $_POST['custom_post_meta_box_nonce'] ) ) {
		return $post_id;
	}
    if (!wp_verify_nonce($_POST['custom_post_meta_box_nonce'], basename(__FILE__))) 
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
    foreach ($post_custom_meta_fields as $field) {
        $old = get_post_meta($post_id, $field['id'], true);
        if (isset ($_POST[$field['id']])) {
            $new = esc_html($_POST[$field['id']]);
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
add_action('save_post', 'save_rehub_post_custom_meta');

?>