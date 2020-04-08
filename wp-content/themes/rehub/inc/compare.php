<?php

/*-----------------------------------------------------------------------------------*/
# 	Compare functions
/*-----------------------------------------------------------------------------------*/

/*ADD COMPARE QUERY VAR*/
function add_query_vars_compareids( $vars ){
   $vars[] = "compareids";
   return $vars;
}
add_filter( 'query_vars', 'add_query_vars_compareids' );

/*ADD PANEL TO FOOTER*/
function rehub_comparepanel_footer(){
	?>
	<?php $compare_url = rehub_option('compare_page'); ?>
	<?php $compare_btncolor = (rehub_option('compare_btn_color') !='') ? rehub_option('compare_btn_color') : 'green'; ?>
	<?php if (get_the_ID() != $compare_url) :?>
		<div id="re-compare-panel">
			<div id="re-compare-panel-heading">
				<span class="re-compare-panel-title leftfloat"><?php _e('Compare items', 'rehub_framework');?> (<span></span>)</span>
				<span class="re-compare-panel-collapse"></span>
				<span class="re-compare-dest wpsm-button <?php echo $compare_btncolor;?> medium right mt5 mr5" data-compareurl="<?php echo esc_url(get_the_permalink($compare_url)) ?>"><i class="fa fa-balance-scale"></i><?php _e('compare', 'rehub_framework');?></span>
			</div>
			<div id="re-compare-wrap"></div>
			
		</div>
	<?php endif;?>
	<?php
}
add_action('wp_footer', 'rehub_comparepanel_footer');


/*PANEL VIEW*/
if (!function_exists('re_compare_item_in_panel')) {
	function re_compare_item_in_panel($compareid) {
		
		$image_id = get_post_thumbnail_id($compareid);  
		$image_url = wp_get_attachment_image_src($image_id,'thumbnail');  
		$img = $image_url[0];				
		$nothumb = get_template_directory_uri() . '/images/default/noimage_100_70.png';
		$imgparams = array('height' => 43, 'crop' => false);
		$compare_title = get_the_title($compareid); 
		$compare_title_truncate = rehub_truncate_title(55, $compareid);		
		$out = '<div class="re-compare-item compare-item-'.$compareid.'" data-compareid="'.$compareid.'">';	
			$out .= '<i class="fa fa-times-circle re-compare-close"></i>';
			$out .= '<div class="re-compare-img">';
				$out .= '<a href="'.get_the_permalink($compareid).'">';
                    if(!empty($img)) :
                        $out .= '<img src="'.bfi_thumb( $img, $imgparams).'" alt="'.$compare_title.'" />';
                    else :   
                        $out .= '<img src="'.$nothumb.'" alt="'.$compare_title.'" />';
                    endif; 					
				$out .= '</a>';
			$out .= '</div>';
			$out .= '<div class="re-compare-title">';
				$out .= '<a href="'.get_the_permalink($compareid).'">'; 
                    $out .= $compare_title_truncate; 					
				$out .= '</a>';
			$out .= '</div>';				
		$out .= '</div>';
		
		return $out;
	}
}

if( !function_exists('re_compare_panel') ) {
function re_compare_panel(){
	$out = '';	
	$count = '';
	$arr = array();
	#user identity
	$ip = rehub_get_ip();
	$userid = get_current_user_id();
	$userid = empty($userid) ? $ip : $userid;
	#existing option
	$option = esc_html(get_transient('re_compare_' . $userid));
	if(!empty($option)) {
		$arr = explode(',',$option);
		$count = count($arr);

	}
	$cssactive = empty($arr) ? '' : 'active';
	
	foreach($arr as $compareid) {
		$out .= re_compare_item_in_panel($compareid);
	}

	$comparing_string = implode(',',$arr);
	
	#generate the response
	$response = json_encode( array( 'content' => $out, 'cssactive' => $cssactive, 'comparing' => $comparing_string, 'count' => $count ) );
 
	#response output
	header( "Content-Type: application/json" );
	echo $response;
	
	exit;
}
}
add_action('wp_ajax_re_compare_panel', 're_compare_panel');
add_action('wp_ajax_nopriv_re_compare_panel', 're_compare_panel');

/*COMPARE AJAX*/
if(!function_exists('re_add_compare')) {	
	#compare toggling
	function re_add_compare() {
		$arr = array();
		$count = '';
		$compareid = (int)$_POST['compareID'];
		$perform = $_POST['perform'];			
		#user identity
		$ip = rehub_get_ip();
		$userid = get_current_user_id();
		$userid = empty($userid) ? $ip : $userid;
		#existing option
		$option = get_transient('re_compare_' . $userid);
		switch($perform) {
			case 'add':
				if(empty($option)) {
					$arr[] = $compareid;
					set_transient('re_compare_' . $userid, $compareid, 30 * DAY_IN_SECONDS);
				} else {
					$arr = explode(',',$option);
					$arr[] = $compareid;
					$newvalue = implode(',',$arr);
					set_transient('re_compare_' . $userid, $newvalue, 30 * DAY_IN_SECONDS);
				}
			break;
			case 'remove':
				$arr = explode(',',$option);
				if(($key = array_search($compareid, $arr)) !== false) {
					unset($arr[$key]);
				}
				$newvalue = implode(',',$arr);
				if (empty($newvalue)) {
					delete_transient('re_compare_' . $userid);
				}
				else {
					set_transient('re_compare_' . $userid, $newvalue, 30 * DAY_IN_SECONDS);
				}
				
			break;	
		}
				
		#html output
		$out = re_compare_item_in_panel($compareid);
		$count = count($arr);
		$comparing_string = implode(',',$arr);
		
		#generate the response
		$response = json_encode( array( 'content' => $out, 'comparing' => $comparing_string, 'count' => $count  ) );
	 
		#response output
		header( "Content-Type: application/json" );
		echo $response;
		
		exit;	
	}
}
add_action('wp_ajax_re_add_compare', 're_add_compare');
add_action('wp_ajax_nopriv_re_add_compare', 're_add_compare');