<?php 

$base_post = $post;
global $post;
$relatives = (rehub_option('rehub_enable_tag_relative') == '1') ? get_the_tags($post->ID) : get_the_category($post->ID);
if ($relatives) {
	$relative_ids = array();
	foreach($relatives as $individual_relative) $relative_ids[] = $individual_relative->term_id;	
	$args = array(
		'post__not_in'     => array($post->ID),
		'posts_per_page'   => 3,
		'ignore_sticky_posts' => 1
	);
	if (rehub_option('rehub_enable_tag_relative') == '1') {
		$args['tag__in'] = $relative_ids;
	}
	else {
		$args['category__in'] = $relative_ids;
	}
	$my_query = new wp_query( $args );
	if( $my_query->have_posts() ) { ?>
		<div class="related_articles clearfix"><div class="related_title"><?php _e('Related Articles', 'rehub_framework'); ?></div><ul>
		<?php while( $my_query->have_posts() ) {
			$my_query->the_post();?>
			<li>				
				<a href="<?php echo get_permalink() ?>"><?php wpsm_thumb('grid_news');?></a>			
				<a href="<?php echo get_permalink() ?>" rel="bookmark" title="<?php the_title(); ?>"><?php the_title(); ?></a>		
			</li>
		<?php
		}
		echo '</ul></div>';
	}
}
$post = $base_post;
wp_reset_query();
?>