<?php if( is_category() || is_singular('post') ){
	if( is_category() ) $cat_id = get_query_var('cat') ;
	if( is_single() ){ 
		$categories = get_the_category( $post->ID );
		$cat_id = $categories[0]->term_id ;
	}
	$cat_data = get_option("category_$cat_id");
}
?>
<?php if (vp_metabox('rehub_framework_brand.rehub_branded_banner_image_single') && (is_single() || is_page())) :?>
  <?php $branded_banner_url = vp_metabox('rehub_framework_brand.rehub_branded_banner_url_single');?>
  <?php $branded_banner_image = vp_metabox('rehub_framework_brand.rehub_branded_banner_image_single');?>
  <div id="branded_img">
  <?php if ($branded_banner_url !='') : ?><a href="<?php echo $branded_banner_url; ?>" target="_blank"><?php endif; ?>
  	<?php if (stripos($branded_banner_image, 'http://') == 0) : ?>
    	<img alt="" src="<?php echo esc_url($branded_banner_image); ?>">
	<?php else :?>
		<?php echo do_shortcode ($branded_banner_image);?>
	<?php endif;?>
  <?php if ($branded_banner_url !='') : ?></a><?php endif; ?>
  </div> 
<?php elseif (!empty($cat_data['cat_image_url']) && (is_single() || is_category())  ) :?>
  <?php $branded_banner_url = (!empty($cat_data['cat_banner_url'])) ? $cat_data['cat_banner_url'] : '';?>
  <?php $branded_banner_image = $cat_data['cat_image_url'];?>
  <div id="branded_img">
  <?php if ($branded_banner_url !='') : ?><a href="<?php echo $branded_banner_url; ?>" target="_blank" rel="nofollow"><?php endif; ?>
  	<?php if (stripos($branded_banner_image, 'http://') == 0) : ?>
    	<img alt="" src="<?php echo esc_url($branded_banner_image); ?>">
	<?php else :?>
		<?php echo do_shortcode ($branded_banner_image);?>
	<?php endif;?>
  <?php if ($branded_banner_url !='') : ?></a><?php endif; ?>
  </div> 
  <style>.top_theme { display: none }</style>
<?php elseif (rehub_option('rehub_branded_banner_image') ) :?>
    <?php $branded_banner_url = rehub_option('rehub_branded_banner_url');?>
    <?php $branded_banner_image = rehub_option('rehub_branded_banner_image');?>
    <div id="branded_img">
    <?php if ($branded_banner_url !='') : ?><a href="<?php echo $branded_banner_url; ?>" target="_blank" rel="nofollow"><?php endif; ?>
        <?php if (stripos($branded_banner_image, 'http://') == 0) : ?>
    	   <img alt="" src="<?php echo esc_url($branded_banner_image); ?>">
	    <?php else :?>
		    <?php echo do_shortcode ($branded_banner_image);?>
	    <?php endif;?>
    <?php if ($branded_banner_url !='') : ?></a><?php endif; ?>
  </div>  
<?php endif; ?>