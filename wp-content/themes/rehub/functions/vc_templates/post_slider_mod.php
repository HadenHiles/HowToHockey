<?php 
	$module_cat = $module_tag = $module_fetch = $exerpt_count = $height = '' ;
    $atts = vc_map_get_attributes( $this->getShortcode(), $atts );
    extract( $atts );
    if ($module_fetch =='') {$module_fetch = '4';}
	if(($module_cat) == 'all') {
		$module_cat = '';
	}
	$slider_height = ($height !='') ? ' style="height:'.$height.';"' : '';	
	$slider_item_height = ($height !='') ? ' height:'.$height.' !important;line-height:'.$height.' !important;' : '';    
?>
<?php if( !is_paged()) : ?>
<?php  wp_enqueue_script('flexslider');  ?>
<section class="clearfix">
    <!-- Feature Slider -->
    <div class="flexslider loading main_slider full_width_slider"<?php echo $slider_height;?>>
    	<i class="fa fa-spinner fa-pulse"></i>
    	<ul class="slides">
    		<?php $post_slider = new WP_Query(array( 'cat' => $module_cat, 'tag' => $module_tag, 'post_type' => 'post', 'showposts' => $module_fetch, 'ignore_sticky_posts' => 1)); ?>
		        <?php if ($post_slider->have_posts()) : while ($post_slider->have_posts()) : $post_slider->the_post(); ?>
	      		<?php 
	      	  		$image_id = get_post_thumbnail_id(get_the_ID());  
			      	$image_url = wp_get_attachment_image_src($image_id,'full');
	          		$image_url = $image_url[0];
	          		if (empty($image_url)) {$image_url = get_template_directory_uri() . '/images/default/noimage_765_460.jpg';}
	      		?>
	        	<li class="slide" style="background-image: url('<?php echo $image_url ;?>');<?php echo $slider_item_height ;?>"> 
	        		<span class="pattern"></span>
	          		<div class="flex-overlay">
	            		<div class="post-meta">
	              			<div class="inner_meta"><?php $category = get_the_category(get_the_ID()); $first_cat = $category[0]->term_id; meta_small( false, $first_cat, false ); ?></div>
	            		</div>
	            		<h2><a href="<?php the_permalink();?>"><?php the_title();?></a></h2>
	            		<?php if ($exerpt_count !='') :?><div class="hero-description"><p><?php kama_excerpt('maxchar='.$exerpt_count.''); ?></p></div><?php endif ;?>
	            		<?php if(rehub_option('disable_btn_offer_loop')!='1')  : ?><?php rehub_create_btn('yes') ;?><?php endif; ?>	            		
	            	</div>
	            	<?php if (rehub_option('exclude_comments_meta') == 0) : ?><?php comments_popup_link( 0, 1, '%', 'comment', ''); ?><?php endif ;?> 
	        	</li>
		        <?php endwhile; endif; wp_reset_query(); ?>
    	</ul>
    </div>
    <!-- /Feature Slider --> 
</section> 
<?php endif ; ?>