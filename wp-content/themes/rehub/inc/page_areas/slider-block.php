<?php 
	$title_enable = vp_metabox('mag_builder_page.pagebuilders.'.$pbid.'.slider_mod.0.slider_toggle_title');
	$title_name = vp_metabox('mag_builder_page.pagebuilders.'.$pbid.'.slider_mod.0.slider_title');
	$title_position = vp_metabox('mag_builder_page.pagebuilders.'.$pbid.'.slider_mod.0.slider_title_position');
	$title_url_title = vp_metabox('mag_builder_page.pagebuilders.'.$pbid.'.slider_mod.0.slider_url_text');
	$title_url_url = vp_metabox('mag_builder_page.pagebuilders.'.$pbid.'.slider_mod.0.slider_url_url');
	$module_fetch = vp_metabox('mag_builder_page.pagebuilders.'.$pbid.'.slider_mod.0.slider_fetch');
	$module_cats = vp_metabox('mag_builder_page.pagebuilders.'.$pbid.'.slider_mod.0.slider_cats');
	$module_enable = vp_metabox('mag_builder_page.pagebuilders.'.$pbid.'.slider_mod.0.slider_toggle_posts');
	$module_exclude = rehub_option('rehub_exclude_posts');
	if(($module_exclude) == 1) {
			$exclude_posts = rehub_exclude_feature_posts();
	}
	else $exclude_posts = '';		    
?>

<?php title_custom_block ($title_enable, $title_name, $title_position, $title_url_title, $title_url_url) ?>
<?php  wp_enqueue_script('flexslider');  ?>
<section class="clearfix">
    <!-- Feature Slider -->
    <div class="flexslider loading main_slider full_width_slider">
    	<i class="fa fa-spinner fa-pulse"></i>
    	<ul class="slides">
    		<?php if ($module_enable == '0') : ?>
		    	<?php 
		    	$args = array(
		          	'showposts' => $module_fetch,
				   	'ignore_sticky_posts' => 1,
		          	'meta_query' => array(
		            	array(
		              		'key' => 'is_featured',
		              		'value' => '1'
		            	),
		            	array(
		              		'key' => 'filter_featured_for',
		              		'value' => 'featured_for_slider'
		            	)
		          	)
		        )
		        ;?>
		    <?php else :?>
				<?php $args = array( 'cat' => $module_cats, 'post_type' => 'post', 'showposts' => $module_fetch, 'post__not_in' => $exclude_posts,  'ignore_sticky_posts' => 1);?>		    	
			<?php endif ;?>
	        <?php $post_slider = new WP_Query($args); if ($post_slider->have_posts()) : ?>
	        <?php while ($post_slider->have_posts()) : $post_slider->the_post(); ?>
	      		<?php 
	      	  		$image_id = get_post_thumbnail_id(get_the_ID());  
			      	$image_url = wp_get_attachment_image_src($image_id,'full');
	          		$image_url = $image_url[0];
	          		if (empty($image_url)) {$image_url = get_template_directory_uri() . '/images/default/noimage_765_460.jpg';}
	      		?>		        	
	          	<li class="slide" style="background-image: url('<?php echo $image_url ;?>');">
	          		<span class="pattern"></span>
	            	<div class="flex-overlay">
	              		<div class="post-meta">
	                		<div class="inner_meta"><?php $category = get_the_category($post->ID); $first_cat = $category[0]->term_id; meta_small( false, $first_cat, false ); ?></div>
	              		</div>
	              		<h2><a href="<?php the_permalink();?>"><?php the_title();?></a></h2>
	              		<?php if(rehub_option('disable_btn_offer_loop')!='1')  : ?><?php rehub_create_btn('yes') ;?><?php endif; ?>
	            	</div>
	            	<?php comments_popup_link( 0, 1, '%', 'comment', ''); ?>
	          	</li>
	        <?php endwhile; endif; wp_reset_query(); ?>
    	</ul>
    </div>
    <!-- /Feature Slider --> 
</section> 